import 'lottie_keyframe.dart';
import 'lottie_shape.dart';

/// A normalized interval of animated Bézier geometry.
class LottiePathKeyframe {
  const LottiePathKeyframe({required this.start, required this.end, required this.timing});

  /// Geometry at the beginning of the interval.
  final LottiePath start;

  /// Geometry approached at the next keyframe, before any discontinuity.
  final LottiePath end;

  /// Time, hold flag, and easing for normalized interpolation from zero to one.
  final LottieScalarKeyframe timing;
}
