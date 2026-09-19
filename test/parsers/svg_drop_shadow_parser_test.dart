import 'dart:io';

import 'package:dotdart/src/parsers/lottie_parser.dart';
import 'package:dotdart/src/parsers/svg/svg_drop_shadow_parser.dart';
import 'package:dotdart/src/parsers/svg/svg_mini_xml.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('test/fixtures/generated_consumer/assets/icons/drop_shadow.svg').readAsStringSync();
  final filter = source.substring(source.indexOf('<filter '), source.indexOf('</filter>') + 9);

  test('when parsing an exported shadow, it should preserve its region and effect parameters', () {
    final shadow = SvgDropShadowParser.parse(XParser.parse(filter));
    expect(
      (
        shadow.x,
        shadow.y,
        shadow.width,
        shadow.height,
        shadow.dx,
        shadow.dy,
        shadow.sigma,
        shadow.alphaScale,
        shadow.color,
      ),
      (0.00380427, -0.000631422, 41.2346, 41.3049, 0.0, 0.370564, 0.419973, 127.0, (0.0, 0.0, 0.0, 0.68)),
    );
  });

  for (final (description, original, replacement) in [
    ('wrong compositing', 'operator="out"', 'operator="in"'),
    ('wrong blend', 'mode="normal"', 'mode="multiply"'),
    ('wrong input', 'in2="hardAlpha"', 'in2="SourceGraphic"'),
    ('wrong alpha source', 'in="SourceAlpha"', 'in="SourceGraphic"'),
    ('wrong blur source', '<feGaussianBlur ', '<feGaussianBlur in="SourceGraphic" '),
    ('nontransparent flood', 'flood-opacity="0"', 'flood-opacity="1"'),
    ('object bounds', 'filterUnits="userSpaceOnUse"', 'filterUnits="objectBoundingBox"'),
    ('linear colors', 'color-interpolation-filters="sRGB"', 'color-interpolation-filters="linearRGB"'),
    ('missing color space', 'color-interpolation-filters="sRGB"', ''),
    ('nonfinite blur', 'stdDeviation="0.419973"', 'stdDeviation="NaN"'),
    ('negative blur', 'stdDeviation="0.419973"', 'stdDeviation="-1"'),
    ('unequal blur axes', 'stdDeviation="0.419973"', 'stdDeviation="1 2"'),
    ('percentage region', 'width="41.2346"', 'width="100%"'),
    ('empty region', 'width="41.2346"', 'width="0"'),
    ('primitive region', '<feOffset ', '<feOffset x="2" '),
    ('extra primitive', '</filter>', '<feOffset/></filter>'),
    ('invalid matrix', '0 0 0 0.68 0', '0 0 0 NaN 0'),
    ('duplicate result', 'result="shape"', 'result="hardAlpha"'),
    ('missing result', 'result="hardAlpha"', ''),
  ]) {
    test('when parsing $description, it should reject the unsupported filter', () {
      expect(
        () => SvgDropShadowParser.parse(XParser.parse(filter.replaceAll(original, replacement))),
        throwsA(isA<DotdartUnsupportedFeatureException>()),
      );
    });
  }
}
