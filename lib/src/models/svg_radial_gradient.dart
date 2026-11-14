import 'svg_element.dart';

/// A centered radial fill in SVG user coordinates.
class SvgRadialGradient {
  const SvgRadialGradient({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.colors,
    required this.stops,
    this.transform,
  });

  final double cx;
  final double cy;
  final double radius;
  final List<(double, double, double, double)> colors;
  final List<double> stops;

  /// Precomposed local transform; absent for the identity transform.
  final SvgMatrix? transform;

  /// SVG defines a zero-radius or single-stop gradient as its last color.
  bool get isSolid => radius == 0 || colors.length == 1;
}
