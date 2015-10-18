using GeoJSON

function bbox(fc::GeoJSON.FeatureCollection)
    outbbox = [Inf,Inf,-Inf,-Inf]
    for (i,shape) in enumerate(fc.features)
        outbbox = _compare_bbox(outbbox, bbox(shape))
    end
    return outbbox
end

function bbox(ft::GeoJSON.Feature)
    isdefined(ft, :bbox) && return ft.bbox
    return bbox(ft.geometry)
end

function bbox(shape::GeoJSON.Polygon)
    if ! isdefined(shape, :bbox)
        bbox::Array{Float64, 1} = [Inf, Inf, -Inf, -Inf]
        for ring in shape.coordinates
            rbox::Array{Float64, 1} = [0,0,0,0]
            rbox[1] = minimum([p[1]::Float64 for p in ring])
            rbox[3] = maximum([p[1]::Float64 for p in ring])
            rbox[2] = minimum([p[end]::Float64 for p in ring])
            rbox[4] = maximum([p[end]::Float64 for p in ring])
            bbox = _compare_bbox(bbox, rbox)
        end
    else
        length(shape.bbox) > 4 && error("only 2-dimensions are implemented")
        bbox = shape.bbox
    end
    return bbox
end

bbox(shape::GeoJSON.MultiPolygon) = bbox(shape::Polygon)

bbox(shape::GeoJSON.Point) = [shape.coordinates, shape.coordinates]

function _compare_bbox(ref::Array{Float64,1}, new::Array{Float64,1})
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

function _compare_bbox(ref::Array{Int64,1}, new::Array{Int64,1})
    return _compare_bbox(float(ref), float(new))
end

function _bbints(ref::Array{Float64,1}, new::Array{Float64,1})
    new[1] < ref[1] < new[3] && new[2] < ref[2] < new[4] && return true #lo left
    new[1] < ref[1] < new[3] && new[2] < ref[4] < new[4] && return true #up left
    new[1] < ref[3] < new[3] && new[2] < ref[4] < new[4] && return true #up right
    new[1] < ref[3] < new[3] && new[2] < ref[2] < new[4] && return true #lo right
    return false
end

function _bbints(ref::Array{Int64, 1}, new::Array{Int64,1})
    return _bbints(float(ref), float(new))
end
