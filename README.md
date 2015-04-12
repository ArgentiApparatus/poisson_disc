# Poisson Disc

A generator of Poisson Disc distributions of points using the Bridson algorithm.

## Functions

Two functions are provided:

    poissonDisc2(num min, num wdth, num hght)

generates a Poisson Disc distribution over an axis aligned bounding box [0,0] → [`wdth`,`hght`] with a minimum separation of `min`.

    poissonDisc2Normalized(int wdth, int hght)

generates a Poisson Disc distribution over an axis aligned bounding box [0,0] → [`wdth`,`hght`] with a minimum separation of √2.

The Bridson algorithm places points it has identified into a grid structure of square cells so that it can efficiently find the separation of new candidate points from nearby points. The grid cell size is chosen so that only one point may fall in each cell (cell width = minimum separation / √2). The implementation of the Bridson algorithm is significantly simplified by assuming a minimum separation of √2 which results in a grid cell width of 1. (`wdth` and`hght` then specify the dimensions of the grid in number of cells.)

`poissonDisc2()` is a wrapper around `poissonDisc2Normalized()`, providing the necessary grid dimensions and scaling the output points to the required separation.

