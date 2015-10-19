#conceptually, the binning algorithm works by dividing the shapefile into a 
#b x b grid, where b is the number of bins. 
using GeoJSON

type Weights
    features::GeoJSON.FeatureCollection
    kind::AbstractString
end


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

