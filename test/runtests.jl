using PyCall,SpatialWeights,FactCheck
@pyimport pysal

shp_path = pysal.examples[:get_path]("columbus.shp")#joinpath(dirname(@__FILE__),"columbus.shp")
json_path = pysal.examples[:get_path]("columbus.json")#joinpath(dirname(@__FILE__),"columbus.json") 
println(shp_path)
println(json_path)

pyqueens = pysal.queen_from_shapefile(shp_path)
pyqueens = pyqueens[:neighbors]
pyqueens = [k+1 => [i+1 for i in v] for (k,v) in pyqueens]
pyrooks = pysal.rook_from_shapefile(shp_path)
pyrooks = pyrooks[:neighbors]
pyrooks = [k+1 => [i+1 for i in v] for (k,v) in pyrooks]

queens = neighbors(GeoJSON.parsefile(json_path), significand=4)
rooks = neighbors(GeoJSON.parsefile(json_path), kind="rook", significand=4)

facts("Queen Contiguity") do
for (k,v) in queens
    allin = reduce(&, [n in pyqueens[k] for n in v])
    noneout = reduce(&, [n in v for n in pyqueens[k]])
    r = allin && noneout
    @fact r --> true "Neighbor set different for $k"
end
end

facts("Rook Contiguity") do
for (k,v) in rooks
    allin = reduce(&, [n in pyrooks[k] for n in v])
    noneout = reduce(&, [n in v for n in pyrooks[k]])
    r = allin && noneout
    @fact r --> true "Neighbor set different for $k"
end
end
