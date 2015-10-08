part of poisson_disc;

const int _maxAttempts = 30; // Value from Bridson algorithm paper
const int _bufferWidth = 2;
const int _twoBufferWidth = _bufferWidth * 2;
const double _twoPi = 2.0 * PI;

/// Poisson Disc generators using Bridson's algorithm.
class Bridson2 {

  /**
   * Generates a Poisson Disc distribution over an axis aligned bounding box (AABB) &lsqb;0,0&rsqb; → &lsqb;[wdth],[hght]&rsqb; with a minimum point separation √2.
   *
   * Toroidal distributions can be tiled with themselves and preserve poisson disc properties across their abutting edges and corners.
   *
   * If [wdth] is [null] and [hght] is not [null], [wdth] is set to [hght].
   * If [hght] is [null] and [wdth] is not [null], [hght] is set to [wdth].
   * 
   * if [toroidal] is [false], the minumum values of both the width and height of the ouput distribtion AABB is 1.
   * if [toroidal] is [true], the minumum values of both the width and height of the ouput distribtion AABB is 5.
   * This value is a consequence of the way that toroidal distributions are produced by the function.
   * 
   * Random number generator may be provided, if not new [Random] is created.
   * 
   */
  static Iterable<Vector2> aabbNative({int wdth, int hght, bool toroidal:false, Random random}) sync* {

    if(wdth == null && hght != null) wdth = hght; else if(hght == null && wdth != null) hght = wdth;
    
    if(wdth == null || wdth < 1 + (toroidal ? _twoBufferWidth : 0)) wdth = 1 + (toroidal ? _twoBufferWidth : 0);
    if(hght == null || hght < 1 + (toroidal ? _twoBufferWidth : 0)) hght = 1 + (toroidal ? _twoBufferWidth : 0);

    if(random == null) random = new Random();

    // Working disc radius = SQRT2, grid cell size = 1.0  
    // Grid is extended by _bufferWidth cells on each side to implement toroidal distribution

    final int gWdth = wdth + (_bufferWidth * 2);  // Grid width
    final int gHght = hght + (_bufferWidth * 2);  // Grid height
    
    final int uuu = wdth + _bufferWidth; // Precalculated value used repeatedly
    final int vvv = hght + _bufferWidth; // Precalculated value used repeatedly

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

        //cand = new Vector2(activeList[c].x + (rad * cos(ang)), activeList[c].y + (rad * sin(ang)));
        cand = new Vector2(nextActive.x + (rad * cos(ang)), nextActive.y + (rad * sin(ang)));

        // Candidate grid cell coordinates
        gx = cand.x.floor() + _bufferWidth;
        gy = cand.y.floor() + _bufferWidth;
        
        // Discard candidates outside of working area
        if (gx >= _bufferWidth && gx < uuu && gy >= _bufferWidth && gy < vvv) {
          
          // Test cells in groups of *decreasing* probabilty of containing a point too close to candidate

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
          
          activeList.add(cand); // Cand becomes activeList
          activeList.add(nextActive); // Keep current active point active list
          gridFunc(); // Put point in grid

          yield cand.clone();      
          break; // We found a new point, so break from loop
        }
      }
    }  
  }


  /**
   * Generates a Poisson Disc distribution over an axis aligned bounding box (AABB) &lsqb;0,0&rsqb; → &lsqb;[wdth],[hght]&rsqb; with a minimum point separation 1.
   * 
   * Calls [aabbNative()] internally then scales generated points.
   */
  static Iterable<Vector2> aabbNorm({int wdth, int hght, bool toroidal:false, Random random}) sync* {
    // TODO
  }


  /**
   * Generates a Poisson Disc distribution over an axis aligned bounding box (AABB) [area] with a minimum point separation [min].
   * 
   * Calls [aabbNative()] internally then scales and translates generated points.
   * 
   * === TODO how aabb is dealt with ===
   * 
   */ 
  static Iterable<Vector2> aabb({Aabb2 area, double min, bool toroidal:false, Random random}) sync* {
    // TODO
  }


}
