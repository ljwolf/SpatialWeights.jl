module SpatialWeights

include(joinpath(dirname(@__FILE__), "bboxer.jl"))
include(joinpath(dirname(@__FILE__), "weights.jl"))

export neighbors, Weights

end # module
