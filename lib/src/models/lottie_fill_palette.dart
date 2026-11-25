import 'lottie_animated_scalar.dart';

typedef LottieGradientGeometry = ({double x, double y, double endX, double endY, bool radial});
typedef LottiePalettePose = ({List<int> start, List<int> end});

/// Build-time color samples in ARGB order. Gradients use one color per stop.
class LottieFillPalette {
  const LottieFillPalette({required this.poses, required this.timing, required this.stops, this.geometry});

  final List<LottiePalettePose> poses;
  final LottieAnimatedScalar timing;
  final List<double> stops;
  final LottieGradientGeometry? geometry;
}
