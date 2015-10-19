using PyCall,SpatialWeights,FactCheck

@pyimport pysal
pyqueens = pysal.queen_from_shapefile("./columbus.shp")
pyqueens = queens[:neighbors]
pyqueens = [k+1 => [i+1 for i in v] for (k,v) in queens]
pyrooks = pysal.rook_from_shapefile("./columbus.shp")
pyrooks = rooks[:neighbors]
pyrooks = [k+1 => [i+1 for i in v] for (k,v) in rooks]

queens = neighbors(GeoJSON.parsefile("columbus.json"), 4)
rooks = neighbors(GeoJSON.parsefile("columbus.json"), kind="rook", 4)

for (k,v) in queens
    allin = all([n in pyqueens[k] for n in v])
    noneout = all([n in v for n in pyqueens[k]])
    @fact allin && noneout --> true

for (k,v) in rooks
    allin = all([n in pyrooks[k] for n in v])
    noneout = all([n in v for n in pyrooks[k]])
    @fact allin && noneout --> true
