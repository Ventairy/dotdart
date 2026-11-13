import 'package:dotdart/src/parsers/svg/svg_geometry_bounds.dart';
import 'package:dotdart/src/parsers/svg/svg_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when bounding Bezier geometry, it should include control points conservatively', () {
    final path = SvgParser.parse(
      '<svg viewBox="0 0 100 100"><path d="M10 20C-5 200 150 -10 90 80"/></svg>',
    ).document.children.single;
    expect(SvgGeometryBounds.of(path), (-5.0, -10.0, 150.0, 200.0));
  });

  test('when bounding a rotated arc with corrected radii, it should include its entire ellipse', () {
    final path = SvgParser.parse(
      '<svg viewBox="0 0 100 100"><path d="M0 0A1 2 45 1 0 100 100"/></svg>',
    ).document.children.single;
    final bounds = SvgGeometryBounds.of(path);
    expect(
      [bounds.$1, bounds.$2, bounds.$3, bounds.$4],
      [lessThan(-100), lessThan(-100), greaterThan(200), greaterThan(200)],
    );
  });
}
