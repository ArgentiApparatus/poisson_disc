# Poisson Disc

Generators of Poisson Disc point distributions.

## Installing

## Usage

### Bridson

Bridson Poisson Disc Distribution generator provides: two 'normalized' distribution methods.

    Iterable<Vector2> Bridson.aabbNative(int wdth, [int hght]) sync* {

    Iterable<Vector2> normalizedToroidal(int wdth, [int hght]) sync* {

Each generates a Poisson Disc distribution over an axis aligned bounding box [0,0] → [`wdth`,`hght`] with a minimum point separation of √2.

This is 'normalized' to the underlying grid that the algorithm uses efficiently find the separation of points. The grid cell size is chosen so that only one point may be in each cell (cell width = minimum separation / √2). The implementation of the Bridson algorithm is significantly simplified by normalizing to a minimum separation √2, which results in a grid cell width of 1. The axis aligned bounding box width and height parameters are integers so that the distribution area can be divided into whole cells. 