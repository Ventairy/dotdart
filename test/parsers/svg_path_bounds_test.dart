import 'dart:math' as math;

import 'package:dotdart/src/models/svg_element.dart';
import 'package:dotdart/src/parsers/lottie_parser.dart';
import 'package:dotdart/src/parsers/svg/svg_parser.dart';
import 'package:dotdart/src/parsers/svg/svg_path_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (data, expected) in [
    ('M0 0C100 100 100 100 0 100Z', (left: 0.0, top: 0.0, width: 75.0, height: 100.0)),
    ('M0 0Q100 100 200 0Z', (left: 0.0, top: 0.0, width: 200.0, height: 50.0)),
    ('M10 10C20 20 30 30 40 40Z', (left: 10.0, top: 10.0, width: 30.0, height: 30.0)),
    ('M0 0Q50 50 100 100Z', (left: 0.0, top: 0.0, width: 100.0, height: 100.0)),
    ('M0 0C-100 -100 -100 -100 0 -100Z', (left: -75.0, top: -100.0, width: 75.0, height: 100.0)),
    ('M0 0Q10 0 20 0L40 10ZL-10 -20', (left: -10.0, top: -20.0, width: 50.0, height: 30.0)),
  ]) {
    test('when bounding $data, it should use segment extrema instead of control points', () {
      final path =
          SvgParser.parse('<svg viewBox="0 0 200 200"><path d="$data"/></svg>').document.children.single as SvgPath;
      expect(SvgPathBounds.calculate(path), expected);
    });
  }

  test('when a cubic has two interior extrema, it should include both exact values', () {
    final path =
        SvgParser.parse(
              '<svg viewBox="0 0 100 100"><path d="M0 0C0 200 100 -200 100 0"/></svg>',
            ).document.children.single
            as SvgPath;
    final bounds = SvgPathBounds.calculate(path);
    expect(
      [bounds.left, bounds.top, bounds.width, bounds.height],
      [0.0, closeTo(-100 / math.sqrt(3), 1e-10), 100.0, closeTo(200 / math.sqrt(3), 1e-10)],
    );
  });

  test('when a derivative root is outside its segment, it should keep endpoint bounds', () {
    final path =
        SvgParser.parse('<svg viewBox="0 0 100 100"><path d="M0 0Q10 10 30 30"/></svg>').document.children.single
            as SvgPath;
    expect(SvgPathBounds.calculate(path), (left: 0.0, top: 0.0, width: 30.0, height: 30.0));
  });

  test('when bounding an arc for a shape-relative image pattern, it should explain supported alternatives', () {
    final path =
        SvgParser.parse('<svg viewBox="0 0 100 100"><path d="M0 0A5 5 0 0 1 10 0"/></svg>').document.children.single
            as SvgPath;
    expect(
      () => SvgPathBounds.calculate(path),
      throwsA(
        isA<DotdartUnsupportedFeatureException>().having(
          (error) => error.message,
          'message',
          contains('Convert arcs to cubic curves'),
        ),
      ),
    );
  });
}
