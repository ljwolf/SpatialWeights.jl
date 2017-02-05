module SpatialWeights

include(joinpath(dirname(@__FILE__), "weights.jl"))

export neighbors, Wmatrix, Weights, WeightsQ, WeightsR, spWeightsQ, spWeightsR

end # module
