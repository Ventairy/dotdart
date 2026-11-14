import 'package:dotdart/src/models/svg_radial_gradient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (radius, colors, expected) in [
    (0.0, [(0.0, 0.0, 1.0, 1.0), (0.0, 0.0, 1.0, 0.0)], true),
    (1.0, [(0.0, 0.0, 1.0, 0.5)], true),
    (1.0, [(0.0, 0.0, 1.0, 1.0), (0.0, 0.0, 1.0, 0.0)], false),
  ]) {
    test('when radius is $radius with ${colors.length} stops, it should resolve solid fills as $expected', () {
      expect(
        SvgRadialGradient(
          cx: 0,
          cy: 0,
          radius: radius,
          colors: colors,
          stops: colors.length == 1 ? const [0] : const [0, 1],
        ).isSolid,
        expected,
      );
    });
  }
}
