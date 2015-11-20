import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:svg';
import 'package:poisson_disc/bridson2.dart' as bridson2;
import 'package:regular_grid/regular_grid2.dart';
import 'package:vector_math/vector_math.dart';

const int _PAD = 2;
const int _TWO_PAD = _PAD * 2;
const int _WDTH = 64;
const int _HGHT = 24;
const int _HISTO_RUNS = 64;
const int _HISTO_MAX = 50;

final Random _random = new Random();

Timer timer;

class Display {

  final DivElement div;
  final bool pad;

  final fSetup;
  final fInit;
  final fRedo;

  SvgSvgElement svg;

  Display(this.div, this.pad, this.fSetup, this.fInit, this.fRedo);
}

void main() {

  List<Display> displays = new List<Display>();

  displays.add(new Display(querySelector('#d0'), false, setup, x0, x4));
  displays.add(new Display(querySelector('#d1'), false, setup, x1, x1));
  displays.add(new Display(querySelector('#d2'), true,  setup, x2, x2));
  displays.add(new Display(querySelector('#d3'), false, setup, x3, x3));

  void x(Event e) {
    for (Display d in displays) {
      if (d.svg == null &&
          (window.pageYOffset + window.innerHeight) > d.div.offsetTop &&
          window.pageYOffset < (d.div.offsetTop + d.div.scrollHeight)) {
        d.svg = d.fSetup(d.pad, d.div);
        d.fInit(d.svg);
        d.svg.onClick.listen((_) {
          d.fRedo(d.svg);
        });
      }
    }
  }

  window.onScroll.listen(x);
  window.onLoad.listen(x);
  window.onResize.listen(x);
}

SvgSvgElement setup(final bool pad, final DivElement div) {
  final int p = pad ? _PAD : 0;

  SvgSvgElement svg = new SvgSvgElement()
    ..viewBox.baseVal.x = -p
    ..viewBox.baseVal.y = -p
    ..viewBox.baseVal.width = _WDTH + (p * 2)
    ..viewBox.baseVal.height = _HGHT + (p * 2);

  div.append(svg);

  return svg;
}

void x0(SvgSvgElement svg) {
  // Basic point distribution render
  svg.children.clear();
  drawGrid(false, svg);
  for (Vector2 v in bridson2.generate(wdth: _WDTH, hght: _HGHT, random:new Random(0))) {
    drawPoint(v.x, v.y, true, svg);
  }
}

void x1(SvgSvgElement svg) {
  // Non-Toriodal point distribution histogram render
  histogram(bridson2.generate(wdth: _WDTH, hght: _HGHT), svg);
}

void x2(SvgSvgElement svg) {
  // Toriodal point distribution render

  svg.children.clear();
  drawGrid(true, svg);

  for (Vector2 v in bridson2.generate(wdth: _WDTH, hght: _HGHT, toroidal: true)) {
    drawPoint(v.x, v.y, true, svg);

    if (v.x < (_PAD * 2)) {
      drawPoint(v.x + _WDTH, v.y, false, svg);
      if (v.y < (_PAD * 2)) {
        drawPoint(v.x + _WDTH, v.y + _HGHT, false, svg);
      }
    } else if (v.x > (_WDTH - _PAD)) {
      drawPoint(v.x - _WDTH, v.y, false, svg);
      if (v.y > (_HGHT - _PAD)) {
        drawPoint(v.x - _WDTH, v.y - _HGHT, false, svg);
      }
    }
    if (v.y < (_PAD * 2)) {
      drawPoint(v.x, v.y + _HGHT, false, svg);
      if (v.x > (_WDTH - _PAD)) {
        drawPoint(v.x - _WDTH, v.y + _HGHT, false, svg);
      }
    } else if (v.y > (_HGHT - _PAD)) {
      drawPoint(v.x, v.y - _HGHT, false, svg);
      if (v.x < (_PAD * 2)) {
        drawPoint(v.x + _WDTH, v.y - _HGHT, false, svg);
      }
    }
  }
}

void x3(SvgSvgElement svg) {
  // Toriodal point distribution histogram render
  histogram(bridson2.generate(wdth: _WDTH, hght: _HGHT, toroidal: true), svg);
}

void x4(SvgSvgElement svg) {
  // Aninmation
  timer?.cancel();
  svg.children.clear();
  drawGrid(false, svg);
  Iterator<Vector2> foo = bridson2.generate(wdth: _WDTH, hght: _HGHT).iterator;
  timer = new Timer.periodic(new Duration(milliseconds: 8), (Timer t) {
    if (foo.moveNext()) {
      drawPoint(foo.current.x, foo.current.y, true, svg);
    } else {
      t.cancel();
    }
  });
}

void drawGrid(final bool pad, SvgSvgElement svg) {
  final int p = pad ? _PAD : 0;

  for (int i = 1 - p; i < _WDTH + p; i++) {
    svg.append(new LineElement()
      ..x1.baseVal.value = i
      ..x2.baseVal.value = i
      ..y1.baseVal.value = -p
      ..y2.baseVal.value = (_HGHT + p)
      ..classes.add(pad && (i == 0 || i == _WDTH) ? 'area' : 'cell'));
  }

  for (int i = 1 - p; i < _HGHT + p; i++) {
    svg.append(new LineElement()
      ..y1.baseVal.value = i
      ..y2.baseVal.value = i
      ..x1.baseVal.value = -p
      ..x2.baseVal.value = (_WDTH + p)
      ..classes.add(pad && (i == 0 || i == _HGHT) ? 'area' : 'cell'));
  }
}

void drawPoint(final double x, final double y, final bool cheese, SvgSvgElement svg) {
  final String s = cheese ? 'in' : 'out';

  svg.append(new CircleElement()
    ..r.baseVal.value = (SQRT2 / 2)
    ..cx.baseVal.value = x
    ..cy.baseVal.value = y
    ..classes.addAll(['disc', s]));

  svg.append(new CircleElement()
    ..r.baseVal.value = 0.125
    ..cx.baseVal.value = x
    ..cy.baseVal.value = y
    ..classes.addAll(['point', s]));
}

void histogram(Iterable<Vector2> points, SvgSvgElement svg) {
  svg.children.clear();
  GridSpace2 space = new GridSpace2.square(1.0);
  Map<GridIndex2, int> map = new Map<GridIndex2, int>();

  for (int r = 0; r < _HISTO_RUNS; r++) {
    for (Vector2 sample in points) {
      GridIndex2 i = space.indexFrom(sample, floor);
      if (map[i] == null) map[i] = 0;
      map[i]++;
    }
  }
  Vector2 p = new Vector2.zero();
  for (GridIndex2 i in map.keys) {
    space.setPointFrom(i, p);
    svg.append(new RectElement()
      ..x.baseVal.value = p.x
      ..y.baseVal.value = p.y
      ..width.baseVal.value = 1
      ..height.baseVal.value = 1
      ..classes.add('bin')
      ..setAttribute('fill-opacity', '${(map[i]/_HISTO_MAX)}'));
  }
}
