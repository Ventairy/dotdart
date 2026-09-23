import 'lottie_layer.dart';

/// A reusable Lottie precomposition referenced by animation layers.
class LottieComposition {
  const LottieComposition({
    required this.id,
    required this.layers,
    this.width,
    this.height,
  });

  /// Identifier referenced by a precomposition layer (`refId`).
  final String id;

  /// Fallback width in pixels when a referencing layer omits its width.
  final int? width;

  /// Fallback height in pixels when a referencing layer omits its height.
  final int? height;

  /// Layers in rendering order (top to bottom in the Lottie source).
  final List<LottieLayer> layers;
}
