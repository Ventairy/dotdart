import 'package:dotdart/src/models/svg_element.dart';
import 'package:dotdart/src/parsers/lottie_parser.dart';
import 'package:dotdart/src/parsers/svg/svg_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SvgTransform', () {
    test('when parsing translate(tx, ty), it should produce a single operation', () {
      final ops = SvgTransform.parse('translate(10, 20)');

      expect(ops, hasLength(1));
    });

    test('when parsing translate(tx, ty), it should have correct tx and ty', () {
      final ops = SvgTransform.parse('translate(10, 20)');
      final t = ops.first as SvgTranslate;

      expect((t.tx, t.ty), (10, 20));
    });

    test('when parsing translate(tx) without ty, it should use ty=0', () {
      final ops = SvgTransform.parse('translate(15)');
      final t = ops.first as SvgTranslate;

      expect((t.tx, t.ty), (15, 0));
    });

    test('when parsing scale(sx, sy), it should have correct sx and sy', () {
      final ops = SvgTransform.parse('scale(2, 3)');
      final s = ops.first as SvgScale;

      expect((s.sx, s.sy), (2, 3));
    });

    test('when parsing scale(s) without sy, it should use sx as sy', () {
      final ops = SvgTransform.parse('scale(1.5)');
      final s = ops.first as SvgScale;

      expect((s.sx, s.sy), (1.5, 1.5));
    });

    test('when parsing rotate(angle), it should produce a rotate operation', () {
      final ops = SvgTransform.parse('rotate(45)');
      final r = ops.first as SvgRotate;

      expect(r.angle, equals(45));
    });

    test('when parsing rotate(angle) without center, cx and cy should be null', () {
      final ops = SvgTransform.parse('rotate(45)');
      final r = ops.first as SvgRotate;

      expect((r.cx, r.cy), (null, null));
    });

    test('when parsing rotate(angle, cx, cy), it should include the center', () {
      final ops = SvgTransform.parse('rotate(90, 10, 20)');
      final r = ops.first as SvgRotate;

      expect((r.angle, r.cx, r.cy), (90, 10, 20));
    });

    test('when parsing chained transforms, it should return them in order', () {
      final ops = SvgTransform.parse('translate(10, 20) rotate(45)');

      expect(ops, [isA<SvgTranslate>(), isA<SvgRotate>()]);
    });

    test('when parsing the reported arrow matrix, it should preserve its coefficients', () {
      expect(
        SvgTransform.parse('matrix(0.765256464 0 0 0.765256464 2.730063589 2.347435357)'),
        isA<List<SvgTransformOp>>().having(
          (ops) {
            final m = ops.single as SvgMatrix;
            return (m.a, m.b, m.c, m.d, m.e, m.f);
          },
          'coefficients',
          (0.765256464, 0.0, 0.0, 0.765256464, 2.730063589, 2.347435357),
        ),
      );
    });

    test('when parsing comma-separated matrix numbers, it should accept signs and exponents', () {
      final matrix = SvgTransform.parse('matrix(-1e-2, +2, .3, 4., 5E+2, -6)').single as SvgMatrix;
      expect((matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f), (-0.01, 2.0, 0.3, 4.0, 500.0, -6.0));
    });

    for (final (source, index, value) in [('skewX(45)', 4, 1.0), ('skewY(-45)', 1, -1.0)]) {
      test('when parsing $source, it should calculate the skew at build time', () {
        expect((SvgTransform.parse(source).single as SvgMatrix).storage[index], closeTo(value, 1e-14));
      });
    }

    test('when parsing a tiny negative skew, it should preserve its sign and magnitude', () {
      final matrix = SvgTransform.parse('skewX(-1e-20)').single as SvgMatrix;
      expect(matrix.c, closeTo(-1.7453292519943295e-22, 1e-36));
    });

    for (final source in [
      'matrix()',
      'matrix(1 2 3 4 5)',
      'matrix(1 2 3 4 5 6 7)',
      'skewX()',
      'skewY(1 2)',
      'translate()',
      'rotate(1 2)',
      'scale(1 2 3)',
      'matrix(1 0 0 1 0 1e309)',
      'skewX(90)',
      'skewY(-90)',
      'skewX(270)',
      'matrix(1 0 0 1 0 NaN)',
      'matrix(1 0 0 1 0 Infinity)',
      'matrix(1 0 0 1 0 0',
      'matrix(1 0 0 1 0 0) garbage',
      'matrix(1,,0,0,1,0,0)',
      'matrix(1 0 0 1 0 0,)',
      'matrix(1 0 0 1 0 0),',
      'matrix(1 0 0 1 0 0))',
      'translate(1-2)',
    ]) {
      test('when parsing invalid transform $source, it should report a format error', () {
        expect(() => SvgTransform.parse(source), throwsFormatException);
      });
    }

    test('when parsing an empty string, it should return an empty list', () {
      final ops = SvgTransform.parse('');

      expect(ops, isEmpty);
    });

    test('when parsing an unknown function, it should throw an unsupported exception', () {
      expect(() => SvgTransform.parse('unknown(1, 2)'), throwsA(isA<DotdartUnsupportedFeatureException>()));
    });

    test('when parsing translate with a space instead of comma, it should still parse', () {
      final ops = SvgTransform.parse('translate(10 20)');
      final t = ops.first as SvgTranslate;

      expect((t.tx, t.ty), (10, 20));
    });
  });
}
