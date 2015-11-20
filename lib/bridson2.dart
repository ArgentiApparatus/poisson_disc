/**
 * 
 * Poisson Disc point distribution generators employing
 * [Bridson's algorithm](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf)
 * 
 * About Bridson's grid structure:
 * 
 * Bridson's algorithm involves creating candidate points and testing them for conflict with existing points. In order to
 * efficiently find potentially conflicting points a square grid spacial data structure is used. The grid cell size is chosen
 * so that each cell may contain a single point at most (cell width = minimum separtion / √2).
 * 
 * About Toroidal distributions: 
 * 
 * Poisson disc point distributions may be *toroidal*. Toroidal distributions may be topologically mapped onto a toroid (and
 * hence have no edges) while preserving Poisson Disc distribution properties. Hence, a toroidal distribution may be tiled with
 * itself while preserving Poisson Disc properties across abutting edges and corners.
 * 
 */

library bridson2;

import 'dart:collection';
import 'dart:math';
import 'package:vector_math/vector_math.dart';

const int _maxAttempts = 30; // Value from Bridson's algorithm paper
const int _bufferWidth = 2;
const int _twoBufferWidth = _bufferWidth * 2;
const double _twoPi = 2.0 * PI;

/**
 * 
 * Generates a Poisson Disc distributed set of points using Bridson's algorithm.
 * 
 * Generates point distribution with a minimum point separation of √2 over a axis aligned bounding box min:
 * &lsqb;0,0&rsqb; → max: &lsqb;[wdth],[hght]&rsqb - i.e., the width and height of the bounding box are provided in numbers of
 * Bridson's underlying grid cells. This is done to make the implementation of the algorithm as straight forward and efficient as possible.
 * 
 * If [wdth] is [null] and [hght] is not [null], the value for [wdth] used will be [hght].
 * If [hght] is [null] and [wdth] is not [null], the value for [hght] used will be [wdth].
 * If both [wdth] and [hght] are [null] their default minimum values will be used:
 *
 * * If [toroidal] is [false] the minimum default value of [wdth] and [hght] is 1.
 * * If [toroidal] is [true] the minimum value of the width and height is 5.
 * (this restriction is a consequence of the efficient implementation of toroidal distributions that avoids modulo arithmetic.)
 *
 * Note on [Iterator]s:
 * 
 * Each time an [Iterator] is obtained from a [Iterable] returned by a synchronous generator function such as this, the
 * function is invoked anew. Generator functions are not compelled to yield an identical sequence of values across invocations,
 * even if the input values are identical.
 * 
 * This function *will not* yield an identical a sequence of points across invocations with identical input values, unless an
 * explicitly seeded [Random] object is provided.
 * 
 */
Iterable<Vector2> generate({int wdth, int hght, bool toroidal:false, Random random}) sync* {

  if(wdth == null && hght != null) wdth = hght; else if(hght == null && wdth != null) hght = wdth;
  
  if(wdth == null || wdth < 1 + (toroidal ? _twoBufferWidth : 0)) wdth = 1 + (toroidal ? _twoBufferWidth : 0);
  if(hght == null || hght < 1 + (toroidal ? _twoBufferWidth : 0)) hght = 1 + (toroidal ? _twoBufferWidth : 0);

  if(random == null) random = new Random();

  // Working disc radius = SQRT2, grid cell size = 1.0  
  // Grid is extended by _bufferWidth cells on each side to implement toroidal distribution

  final int gWdth = wdth + (_bufferWidth * 2);  // Grid width
  final int gHght = hght + (_bufferWidth * 2);  // Grid height
  
  final int uuu = wdth + _bufferWidth; // Pre-calculated value used repeatedly
  final int vvv = hght + _bufferWidth; // Pre-calculated value used repeatedly

  final List<List<Vector2>> grid = new List<List<Vector2>>.generate(gWdth, (_) => new List<Vector2>.generate(gHght, (_) => null));

  final Queue<Vector2> activeList = new Queue<Vector2>();
  
  Vector2 nextActive, cand, test;
  double rad, ang;
  int a, gx, gy;

  var gridFunc;
  if(toroidal) {
    gridFunc = () {

      grid[gx][gy] = cand;

      // If point in near edge of working area, make a copy in buffer cell on opposite side
      if(gx < _twoBufferWidth) {
        grid[gx + wdth][gy] = cand.clone()..x+=wdth;
        if(gy < _twoBufferWidth) {
          grid[gx + wdth][gy + hght] = cand.clone()..x+=wdth..y+=hght;          
        }
      }
      else if (gx >= wdth) {
        grid[gx - wdth][gy] = cand.clone()..x-=wdth;
        if (gy >= hght) {
          grid[gx - wdth][gy - hght] = cand.clone()..x-=wdth..y-=hght;
        }        }
      if (gy < _twoBufferWidth) {
        grid[gx][gy + hght] = cand.clone()..y+=hght;
        if(gx >= wdth) {
          grid[gx - wdth][gy + hght] = cand.clone()..x-=wdth..y+=hght;
        }
      }
      else if (gy >= hght) {
        grid[gx][gy - hght] = cand.clone()..y-=hght;
        if (gx < _twoBufferWidth) {
          grid[gx + wdth][gy - hght] = cand.clone()..x+=wdth..y-=hght;
        }
      }
    };
  } else {
    gridFunc = () {
      grid[gx][gy] = cand;
    };
  }

  // Generate initial 'candidate' point and add to grid and active list
  cand = new Vector2(wdth * random.nextDouble(), hght * random.nextDouble());
  gx = cand.x.floor() + _bufferWidth;
  gy = cand.y.floor() + _bufferWidth;
  gridFunc();

  activeList.add(cand);
  yield cand.clone();
  
  // Until active list is empty
  while (activeList.isNotEmpty) {

    nextActive = activeList.removeFirst();
    
    // Generate candidate points and test for viability
    a = 0;
    while (a < _maxAttempts) {

      // Candidate point in annulus around considered point
      ang = _twoPi * random.nextDouble();
      rad = SQRT2 + (SQRT2 * random.nextDouble());

      cand = new Vector2(nextActive.x + (rad * cos(ang)), nextActive.y + (rad * sin(ang)));

      // Candidate grid cell coordinates
      gx = cand.x.floor() + _bufferWidth;
      gy = cand.y.floor() + _bufferWidth;
      
      // Discard candidates outside of working area
      if (gx >= _bufferWidth && gx < uuu && gy >= _bufferWidth && gy < vvv) {
        
        // Test cells in groups of *decreasing* probability of containing a point too close to candidate

        // Candidate's cell
        if (grid[gx][gy] != null) { a++; continue; }
        // Inner horz. and vert.
        test = grid[gx + 1][gy];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 1][gy];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx][gy + 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx][gy - 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        // Inner diagonal
        test = grid[gx + 1][gy + 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx + 1][gy - 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 1][gy + 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 1][gy - 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        // Outer horz. and vert.
        test = grid[gx + 2][gy];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 2][gy];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx][gy + 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx][gy - 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        // Outer diagonal
        test = grid[gx + 1][gy + 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx + 1][gy - 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 1][gy + 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 1][gy - 2];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx + 2][gy + 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx + 2][gy - 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 2][gy + 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }
        test = grid[gx - 2][gy - 1];
        if (test != null ? test.distanceToSquared(cand) < 2 : false) { a++; continue; }

        // If we made it here, candidate is a new point
        
        activeList.add(cand); // Cand goes on active list
        activeList.add(nextActive); // Put current active point back in active list
        gridFunc(); // Put point in grid

        yield cand.clone();      
        break; // We found a new point, so break from loop
      }
    }
  }  
}