part of 'svg_element.dart';

/// A two-dimensional SVG matrix: x′ = ax + cy + e, y′ = bx + dy + f.
final class SvgMatrix extends SvgTransformOp {
  const SvgMatrix({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.f,
  });

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  /// Composes operations in SVG source order, without inverting the matrix.
  static SvgMatrix compose(List<SvgTransformOp> operations) {
    var result = const SvgMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0);
    for (final operation in operations) {
      final SvgMatrix next;
      switch (operation) {
        case SvgMatrix():
          next = operation;
        case SvgTranslate(:final tx, :final ty):
          next = SvgMatrix(a: 1, b: 0, c: 0, d: 1, e: tx, f: ty);
        case SvgScale(:final sx, :final sy):
          next = SvgMatrix(a: sx, b: 0, c: 0, d: sy, e: 0, f: 0);
        case SvgRotate(:final angle, :final cx, :final cy):
          final radians = angle.remainder(360) * (math.pi / 180);
          final cosine = math.cos(radians);
          final sine = math.sin(radians);
          final x = cx ?? 0;
          final y = cy ?? 0;
          next = SvgMatrix(
            a: cosine,
            b: sine,
            c: -sine,
            d: cosine,
            e: x - cosine * x + sine * y,
            f: y - sine * x - cosine * y,
          );
      }
      result = SvgMatrix(
        a: result.a * next.a + result.c * next.b,
        b: result.b * next.a + result.d * next.b,
        c: result.a * next.c + result.c * next.d,
        d: result.b * next.c + result.d * next.d,
        e: result.a * next.e + result.c * next.f + result.e,
        f: result.b * next.e + result.d * next.f + result.f,
      );
      if (![result.a, result.b, result.c, result.d, result.e, result.f].every((value) => value.isFinite)) {
        throw const FormatException(
          'SVG transform composition produced non-finite values. Reduce the transform values.',
        );
      }
    }
    return result;
  }

  /// Column-major values for Flutter's four-dimensional canvas matrix.
  List<double> get storage => [a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1];
}
