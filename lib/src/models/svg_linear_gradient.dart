/// A validated linear gradient in SVG user coordinates.
class SvgLinearGradient {
  const SvgLinearGradient({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.colors,
    required this.stops,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final List<(double, double, double, double)> colors;
  final List<double> stops;
}
