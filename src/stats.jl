include(joinpath(dirname(@__FILE__), "weights.jl"))

function is_row_standard(Wmatrix)
    if all([isapprox(i,1.0) for i in sum(Wmatrix,2)])
        return true
    else 
        return false
    end
end

function moran(data, W)
    if size(y) == (length(y),)
        y = resize(y, (length(y), 1))
    if !is_row_standard(W)
        W = W ./ reshape(sum(W,2), size(y))
    num = (Wy - mean(y))'*(y - mean(y))
    SS = (y - mean(y))' * (y - mean(y))
    return num / SS
