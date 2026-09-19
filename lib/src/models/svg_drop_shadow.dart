/// A validated exported SVG drop-shadow filter in local user coordinates.
class SvgDropShadow {
  const SvgDropShadow({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.dx,
    required this.dy,
    required this.sigma,
    required this.alphaScale,
    required this.color,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double dx;
  final double dy;
  final double sigma;
  final double alphaScale;
  final (double, double, double, double) color;
}
