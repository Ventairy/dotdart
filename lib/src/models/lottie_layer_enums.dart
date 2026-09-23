part of 'lottie_layer.dart';

/// Supported ways to use the preceding layer as an opacity mask.
enum LottieMatte {
  /// Paint the layer normally.
  none,

  /// Keep content where the preceding layer is opaque.
  alpha,

  /// Keep content where the preceding layer is transparent.
  invertedAlpha;

  /// Flutter blend mode used to apply the mask to isolated content.
  String get blendMode => switch (this) {
    none => 'srcOver',
    alpha => 'dstIn',
    invertedAlpha => 'dstOut',
  };
}
