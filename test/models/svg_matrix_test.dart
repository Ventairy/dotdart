import 'package:dotdart/src/models/svg_element.dart';
import 'package:dotdart/src/parsers/svg/svg_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when composing a translated scale, it should preserve SVG multiplication order', () {
    final m = SvgMatrix.compose(SvgTransform.parse('translate(10 20) matrix(2 0 0 3 4 5)'));
    expect(m.storage, [2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1, 0, 14, 25, 0, 1]);
  });

  test('when composing a pivoted rotation with skew, it should preserve the pivot and order', () {
    final m = SvgMatrix.compose(SvgTransform.parse('rotate(90 2 3) skewX(45)'));
    expect(
      [m.a, m.b, m.c, m.d, m.e, m.f],
      orderedEquals([
        closeTo(0, 1e-14),
        closeTo(1, 1e-14),
        closeTo(-1, 1e-14),
        closeTo(1, 1e-14),
        5.0,
        closeTo(1, 1e-14),
      ]),
    );
  });

  test('when composing a reflection and zero scale, it should accept a singular matrix', () {
    final m = SvgMatrix.compose(SvgTransform.parse('matrix(-1 0 0 1 10 0) scale(0 2)'));
    expect([m.a, m.b, m.c, m.d, m.e, m.f], [0, 0, 0, 2, 10, 0]);
  });

  test('when composition overflows, it should report a format error', () {
    expect(() => SvgMatrix.compose(SvgTransform.parse('matrix(1e308 0 0 1 0 0) scale(2)')), throwsFormatException);
  });
}
