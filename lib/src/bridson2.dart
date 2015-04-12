part of poisson_disc;

const int _MAX_ATTEMPTS = 30; // Value from Bridson algorithm paper
const int _BUF_WDTH = 5;
const double _TWO_PI = 2.0 * PI;

/**
 * Generates a Poisson Disc distribution over an axis aligned bounding box &lsqb;0,0&rsqb; → &lsqb;[wdth],[hght]&rsqb; with a minimum separation of [min].
 *
 * If negative or null values are provided for [wdth] or [hght] an [ArgumentError] will be thrown.
 *
 * If [random] is provided it will be used as the internal random number generator.
 */
Iterable<Vector2> poissonDisc2(num min, num wdth, num hght, [Random random]) {
  double w = wdth.toDouble(), h = hght.toDouble();
  return poissonDisc2Normalized(((SQRT2 * w) / min).ceil(), ((SQRT2 * h) / min).ceil(), random)
      .where((v) => v.x < w && v.y < h);

}

/**
 * Generates a Poisson Disc distribution over an axis aligned bounding box &lsqb;0,0&rsqb; → &lsqb;[wdth],[hght]&rsqb; with a minimum separation of √2.
 *
 * If negative or null values are provided for [wdth] or [hght] an [ArgumentError] will be thrown.
 *
 * If [random] is provided it will be used as the internal random number generator.
 *
 */
Iterable<Vector2> poissonDisc2Normalized(int wdth, int hght, [Random random]) sync* {

  if(wdth == null) throw new ArgumentError.notNull('wdth');
  if(hght == null) throw new ArgumentError.notNull('hght');
  if(wdth < 0) throw new ArgumentError.value(wdth, 'wdth', 'Must not be negative');
  if(hght < 0) throw new ArgumentError.value(hght, 'hght', 'Must not be negative');

  // Working disc radius = SQRT2, grid cell size = 1.0

  final int gWdth = wdth + (_BUF_WDTH * 2);  // Grid width
  final int gHght = hght + (_BUF_WDTH * 2);  // Grid height
  final List<Vector2> proc = new List<Vector2>();  // Processing list
  final Random _random = random == null ? new Random() : random;

  List<List<Vector2>> grid = new List<List<Vector2>>.generate(gWdth, (_) => new List<Vector2>.generate(gHght, (_) => null));

  Vector2 cand, test;
  double rad, ang;
  int c, a, gx, gy;
  bool active;

  // Generate initial 'candidate' point and add to grid and processing list
  cand = new Vector2(wdth * _random.nextDouble(), hght * _random.nextDouble());
  grid[cand.x.floor() + _BUF_WDTH][cand.y.floor() + _BUF_WDTH] = cand;
  proc.add(cand);
  yield cand.clone(); // Yield *copy* of candidate

  // Until processing list is empty
  while (proc.isNotEmpty) {

    // Index of random 'considered' point in processing list
    c = _random.nextInt(proc.length);

    // Generate candidate points and test for viability
    active = false;
    for (a = 0; a < _MAX_ATTEMPTS; a++) {

      // Candidate point in annulus around considered point
      rad = SQRT2 + (SQRT2 * _random.nextDouble());
      ang = _TWO_PI * _random.nextDouble();
      cand = new Vector2(proc[c].x + (rad * cos(ang)), proc[c].y + (rad * sin(ang)));

      // Candidate grid cell coordinates
      gx = cand.x.floor() + _BUF_WDTH;
      gy = cand.y.floor() + _BUF_WDTH;

      // Test candidate's cell
      if (grid[gx][gy] != null) continue;

      // Test surrounding cells in groups of *decreasing* probabilty of containing a point too close to candidate
      test = grid[gx + 1][gy];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 1][gy];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx][gy + 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx][gy - 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 1][gy + 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 1][gy - 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 1][gy + 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 1][gy - 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 2][gy];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 2][gy];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx][gy + 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx][gy - 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 1][gy + 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 1][gy - 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 1][gy + 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 1][gy - 2];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 2][gy + 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx + 2][gy - 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 2][gy + 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;
      test = grid[gx - 2][gy - 1];
      if (test != null ? test.distanceToSquared(cand) < 2 : false) continue;

      // If we made it here, we have found a new point
      active = true;

      grid[gx][gy] = cand; // Put new point in grid

      // If new point is not in the buffer zone add to pocessing list, yield it up
      if (gx >= _BUF_WDTH && gx < gWdth - _BUF_WDTH && gy >= _BUF_WDTH && gy < gHght - _BUF_WDTH) {
        proc.add(cand);
        yield cand.clone(); // Yield *copy* of candidate
      }

      break; // We found a new point, so break from loop
    }

    // No new points found, considered point is then inactive, remove it from processing list
    if (!active) {
      proc[c] = proc.last;
      proc.removeLast();
    }
  }
  }
