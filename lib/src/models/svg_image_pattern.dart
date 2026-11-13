/// A repeating tile containing one embedded PNG, resolved at build time.
class SvgImagePattern {
  const SvgImagePattern({
    required this.bytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.imageX,
    required this.imageY,
    required this.imageWidth,
    required this.imageHeight,
    required this.objectBoundingBox,
  });

  final List<int> bytes;
  final int pixelWidth;
  final int pixelHeight;
  final double x;
  final double y;
  final double width;
  final double height;
  final double imageX;
  final double imageY;
  final double imageWidth;
  final double imageHeight;
  final bool objectBoundingBox;
}
