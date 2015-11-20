
import "package:test/test.dart";
import 'package:poisson_disc/bridson2.dart';
import 'package:vector_math/vector_math.dart';

class Vector2X extends CustomMatcher {
  Vector2X(matcher): super("Vector2 with x that is", "x", matcher);
  featureValueOf(actual) => actual.x;
}

class Vector2Y extends CustomMatcher {
  Vector2Y(matcher): super("Vector2 with y that is", "y", matcher);
  featureValueOf(actual) => actual.y;
}

class inAabb extends Matcher {

  final Vector2 min;
  final Vector2 max;

  const inAabb(this.min, this.max): super();

  Description describe(Description description) => description..add('range $min → $max');

  bool matches(Vector2 v, dynamic stuff) => v.x < max.x && v.x >= min.x && v.y < max.y && v.y >= min.y;
}


class areSeparatedSqrt2 extends Matcher {

  const areSeparatedSqrt2(): super();

  Description describe(Description description) => description..add('all points are separated by at least √2');

  bool matches(List<Vector2> points, dynamic stuff) {

    for(int p=0; p<points.length-1; p++) {
      for(int q=p+1; q<points.length; q++) {
        if(points[p].distanceToSquared(points[q]) < 2) { return false; }
      }
    }
    return true;
  }
}


void main() {

  group('Base distribution generation:', () {
    List<Vector2> points = new List<Vector2>.from(generate(wdth: 24, hght: 16));

    test("At least one point generated", () {
      expect(points, isNotEmpty);
    });

    test("All points type Vector2 (and not null)", () {
      expect(points, everyElement(allOf(isNotNull, new isInstanceOf<Vector2>())));
    });

    test("All points within distribution area", () {
      expect(points, everyElement(new inAabb(new Vector2.zero(), new Vector2(24.0, 16.0))));
    });

    test("All points have minimum separation", () {
      expect(points, new areSeparatedSqrt2());
    });
  });
}
