SpatialWeights.jl
====================
[![Build Status](https://travis-ci.org/ljwolf/SpatialWeights.jl.svg?branch=master)](https://travis-ci.org/ljwolf/SpatialWeights.jl)

A julia module to construct spatial weights for geospatial data

Right now, a working exact contiguity builder is in place from any GeoJSON
feaure collection.  

Priorities
------------
1. <s>add some kind of tolerance/snapping to improve results</s>
2. <s>validate Queen, Rook> against [PySAL](https://github.com/pysal/pysal)</s>
3. <s>Write testing framework against pysal using pycall</s>
3. <s>Implement full binning</s>
4. Write/find dict to matrix function to convert dict mapping to weights
5. Move past contiguity. 
