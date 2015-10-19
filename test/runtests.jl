using PyCall,SpatialWeights,FactCheck

shp_path = joinpath(dirname(@__FILE__),"columbus.shp")
json_path = joinpath(dirname(@__FILE__),"columbus.json") 

@pyimport pysal
pyqueens = pysal.queen_from_shapefile(shp_path)
pyqueens = queens[:neighbors]
pyqueens = [k+1 => [i+1 for i in v] for (k,v) in queens]
pyrooks = pysal.rook_from_shapefile(shp_path)
pyrooks = rooks[:neighbors]
pyrooks = [k+1 => [i+1 for i in v] for (k,v) in rooks]

queens = neighbors(GeoJSON.parsefile(json_path), 4)
rooks = neighbors(GeoJSON.parsefile(json_path), kind="rook", 4)

for (k,v) in queens
    allin = all([n in pyqueens[k] for n in v])
    noneout = all([n in v for n in pyqueens[k]])
    @fact allin && noneout --> true

for (k,v) in rooks
    allin = all([n in pyrooks[k] for n in v])
    noneout = all([n in v for n in pyrooks[k]])
    @fact allin && noneout --> true
