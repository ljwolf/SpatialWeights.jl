SpatialWeights.jl
====================

A julia module to construct spatial weights for geospatial data

Right now, a working exact contiguity builder is in place from any GeoJSON
feaure collection.  

Priorities
------------
1. add some kind of tolerance/snapping to improve results
2. validate against PySAL
3. Implement full binning
4. Write/find dict to matrix function to convert dict mapping to weights
5. Move past contiguity. 
