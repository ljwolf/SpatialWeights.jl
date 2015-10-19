module bboxer
using GeoJSON
export bbox, crosses

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

end
