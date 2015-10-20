#conceptually, the binning algorithm works by dividing the shapefile into a 
#b x b grid, where b is the number of bins. 
using GeoJSON

type Weights
    features::GeoJSON.FeatureCollection
    kind::AbstractString
end

"""Consruct contiguity weights from a GeoJSON feature collection"""
function neighbors(fc::GeoJSON.FeatureCollection;
                   kind::AbstractString="queen",
                   idfield::AbstractString="",
                   significand::Int64=5)
    results = Dict()

    #index & clean step
    for (i,f) in enumerate(fc.features)
        if idfield != ""
            fc.features[i].id = f.properties[idfield]
        elseif isdefined(f, :id)
            continue
        else
            fc.features[i].id = i
        end
    end
    #w consruction step
    for (i,f) in enumerate(fc.features)
        toadd = []
        id = f.id
        truncated_i = 
        candidates = filter(s -> crosses(bbox(f), bbox(s)) && s.id!=id, fc.features)
        for c in candidates
            j = c.id
            addin = false
            if lowercase(kind) == "queen"
                cpts = [trunc(a, significand) for a in _getcoords(c)]
                for pt in [trunc(a, significand) for a in _getcoords(f)]
                    if pt in cpts && !(j in toadd)
                        append!(toadd, [j])
                    end
                end
            elseif lowercase(kind) == "rook"
                cedges = [trunc(a, significand) for a in _getedges(c)]
                flipped = [reshape([s[3:4];s[1:2]], (1,4)) for s in cedges]
                cedges = vcat(cedges, flipped) #need both cw and ccw
                for edge in [trunc(a, significand) for a in _getedges(f)]
                    if edge in cedges && !(j in toadd)
                        append!(toadd, [j])
                    end
                end
            else
                error("Non Queen/Rook not implemented yet")
            end
        end
        results[id] = toadd
    end
    return results
end

function _getcoords(f::GeoJSON.Feature)
    return _getcoords(f.geometry)
end

function _getcoords(f::Polygon)
    return [p for p in f.coordinates[1]]
end
#_getcoords(f::MultiPolygon) = _getcoords(f::Polygon)

function _getedges(f::GeoJSON.Feature)
    return _getedges(f.geometry)
end

function _getedges(f::Polygon)
    edges = Array(Float64, (1,4))
    updated = false
    for r in f.coordinates
        for (i,pt) in enumerate(r[1:end-1])
            edge = reshape([r[i]; r[i+1]], (1,4))
            if !(edge in [edges[i,:] for i in 1:size(edges)[1]])
                if updated
                    edges = vcat(edges, edge)
                else
                    edges = edge
                    updated = true
                end
            end
        end
    end
    return [edges[i,:] for i in 1:size(edges)[1]]
end
_getedges(f::MultiPolygon) = _getedges(f::Polygon)

"""Compute the total bounding box, also known as the Minimum 
Bounding Rectangle of a GeoJSON feature collection"""
function bbox(fc::GeoJSON.FeatureCollection)
    outbbox = [Inf,Inf,-Inf,-Inf]
    for (i,shape) in enumerate(fc.features)
        outbbox = _update_bbox(outbbox, bbox(shape))
    end
    return outbbox
end

"""Compute the total bounding box, also known as the Minimum 
Bounding Rectangle of a GeoJSON Feature"""
function bbox(ft::GeoJSON.Feature)
    isdefined(ft, :bbox) && return ft.bbox
    return bbox(ft.geometry)
end

"""Compute the total bounding box, also known as the Minimum 
Bounding Rectangle of a GeoJSON Polygon"""
function bbox(shape::GeoJSON.Polygon)
    if ! isdefined(shape, :bbox)
        bbox::Array{Float64, 1} = [Inf, Inf, -Inf, -Inf]
        for ring in shape.coordinates
            rbox::Array{Float64, 1} = [0,0,0,0]
            rbox[1] = minimum([p[1]::Float64 for p in ring])
            rbox[3] = maximum([p[1]::Float64 for p in ring])
            rbox[2] = minimum([p[end]::Float64 for p in ring])
            rbox[4] = maximum([p[end]::Float64 for p in ring])
            bbox = _update_bbox(bbox, rbox)
        end
    else
        length(shape.bbox) > 4 && error("only 2-dimensions are implemented")
        bbox = shape.bbox
    end
    return bbox
end

"""Compute the total bounding box, also known as the Minimum 
Bounding Rectangle of a GeoJSON MultiPolygon"""
bbox(shape::GeoJSON.MultiPolygon) = bbox(shape::Polygon)

"""Compute the total bounding box, also known as the Minimum 
Bounding Rectangle of a GeoJSON Point. For a point, the MBR is
nearly meaningless, so this simply returns a (4,) array with the shape
coordinates doubled."""
bbox(shape::GeoJSON.Point) = [shape.coordinates, shape.coordinates]

"""Update a bounding box. helper function for `bbox` methods"""
function _update_bbox(ref::Array{Float64,1}, new::Array{Float64,1})
    inflection = length(ref) / 2
    for (i,pos) in enumerate(ref)
        if i <= inflection
            pos > new[i] && (ref[i] = new[i])
        else
            pos < new[i] && (ref[i] = new[i])
        end
    end
    return ref
end

"""Update a bounding box. Helper function for `bbox` methods"""
function _update_bbox(ref::Array{Int64,1}, new::Array{Int64,1})
    return _update_bbox(float(ref), float(new))
end

"""Compute whether or not a Minimum Bounding Rectangle/bounding box crosses
another bounding box. By crosses, we mean a spatial intersection. In theory,
this function should use JuliaGeometry types, rather than arrays, and should
become a method of `intersects` rather than defining its own behavior. But,
to get this up and running, it returns a boolean determining whether a
(4,) array representing an MBR crosses another (4,) array representing an MBR."""
function crosses(ref::Array{Float64,1}, new::Array{Float64,1})
    return _crosses(ref, new) || _crosses(new,ref)
end

"""Compute whether or not a Minimum Bounding Rectangle/bounding box crosses
another bounding box. For caveats, refer to:
`crosses(ref::Array{Float64,1}, new::Array{Float64,1})`
"""
function crosses(ref::Array{Int64, 1}, new::Array{Int64,1})
    return crosses(float(ref), float(new))
end

"""Logical switch statements supporting the crosses function"""
function _crosses(ref::Array{Float64,1}, new::Array{Float64,1})
    r = false
    if new[1] <= ref[1] <= new[3] || new[1] <= ref[3] <= new[3]
        r |= ref[2] <= new[2] && ref[4] >= new[2] #ref crosses new
        r |= new[2] <= ref[2] <= new[4]  #bottom corner in new
    elseif new[2] <= ref[2] <= new[4] || new[2] <= ref[4] <= new[4]
        r |= ref[1] <= new[1] && ref[3] >= new[1]  #ref crosses new
        r |= new[1] <= ref[1] <= new[3] #left corner in new
    end
    return r
end

"""Logical switch statements supporting the crosses function"""
function _crosses(ref::Array{Int64,1}, new::Array{Int64,1})
    return _crosses(float(ref), float(new))
end

"""Construct a weights matrix"""
function Wmatrix(ndict::Dict; 
                 sparse::Bool=false,
                 standardize::Bool=false)
    n = length(ndict)
    if sparse
        Wmat = spzeros(n,n) #because zeros allocates non-floats
    else
        Wmat = zeros(Float64, (n,n))
    end
    for (i,(k,v)) in enumerate(ndict)
        if standardize
            denominator = length(v)
        else
            denominator = 1
        end
        if isinteger(k)
            i=k
        end
        Wmat[i,v] = 1 / denominator
    end
    return Wmat
end

function Wmatrix(fc::GeoJSON.FeatureCollection;
                   kind::AbstractString="queen",
                   idfield::AbstractString="",
                   significand::Int64=5,
                   sparse::Bool=false,
                   standardize::Bool=false)
    results = neighbors(fc, 
                        kind=kind, 
                        idfield=idfield, 
                        significand=significand)
    results = Wmatrix(results, 
                      sparse=sparse,
                      standardize=standardize)
    return results
end
