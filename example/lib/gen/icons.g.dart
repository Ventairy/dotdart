// GENERATED CODE - DO NOT MODIFY BY HAND
// *****************************************************
//  dotdart
// *****************************************************

// coverage:ignore-file
// Generated canvas and paint sequences intentionally use repeated receiver calls.
// ignore_for_file: cascade_invocations, unused_element, unused_element_parameter

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

class _DotdartSvgImages extends StatefulWidget {
  const _DotdartSvgImages({
    required this.providers,
    required this.patterns,
    required this.builder,
  });

  final List<ImageProvider<Object>> providers;
  final List<List<_DotdartSvgPattern>> patterns;
  final Widget Function(List<_DotdartSvgDecodedImage?> images) builder;

  @override
  State<_DotdartSvgImages> createState() => _DotdartSvgImagesState();
}

class _DotdartSvgImagesState extends State<_DotdartSvgImages> {
  List<_DotdartSvgDecodedImage?> _images = [];
  List<({ImageProvider<Object> provider, ImageConfiguration configuration})?>
  _resolved = [];
  List<bool> _failed = [];
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageConfiguration? _configuration;
  bool _pumping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final configuration = createLocalImageConfiguration(context);
    if (configuration == _configuration) return;
    _configuration = configuration;
    _reload();
  }

  @override
  void didUpdateWidget(covariant _DotdartSvgImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers.length != widget.providers.length) {
      _reload();
      return;
    }
    for (var index = 0; index < widget.providers.length; index++) {
      if (oldWidget.providers[index] != widget.providers[index]) {
        _reload();
        return;
      }
    }
  }

  Object _source(ImageProvider<Object> provider) =>
      provider is ResizeImage ? provider.imageProvider : provider;

  void _reload() {
    final previousImages = _images;
    final previousResolved = _resolved;
    _images = List.filled(widget.providers.length, null);
    _resolved = List.filled(widget.providers.length, null);
    _failed = List.filled(widget.providers.length, false);
    for (var index = 0; index < previousImages.length; index++) {
      final resolved = previousResolved[index];
      if (index < widget.providers.length &&
          resolved != null &&
          _source(resolved.provider) == _source(widget.providers[index])) {
        _images[index] = previousImages[index];
        _resolved[index] = resolved;
      } else {
        previousImages[index]?.dispose();
      }
    }
    // Keep an active decode until it completes. The image cache may still be
    // decoding after a listener is removed; starting another resize here would
    // allow rapid size changes to create many concurrent decodes.
    _pump();
  }

  void _pump() {
    if (_pumping || !mounted || _configuration == null) return;
    _pumping = true;
    try {
      while (_stream == null) {
        int? next;
        for (var index = 0; index < widget.providers.length; index++) {
          final resolved = _resolved[index];
          if (!_failed[index] &&
              (resolved == null ||
                  resolved.provider != widget.providers[index] ||
                  resolved.configuration != _configuration)) {
            next = index;
            break;
          }
        }
        if (next == null) return;
        _load(next);
      }
    } finally {
      _pumping = false;
    }
  }

  void _load(int index) {
    final provider = widget.providers[index];
    final configuration = _configuration!;
    final stream = provider.resolve(configuration);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronous) {
        stream.removeListener(listener);
        if (!mounted) {
          image.dispose();
          return;
        }
        _stream = null;
        _listener = null;
        if (index < widget.providers.length &&
            _source(provider) == _source(widget.providers[index])) {
          _images[index]?.dispose();
          _images = [..._images]
            ..[index] = _DotdartSvgDecodedImage(image, widget.patterns[index]);
          _resolved[index] = (provider: provider, configuration: configuration);
        } else {
          image.dispose();
        }
        if (!synchronous) setState(() {});
        _pump();
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        if (!mounted) return;
        _stream = null;
        _listener = null;
        if (index < widget.providers.length &&
            provider == widget.providers[index] &&
            configuration == _configuration) {
          _failed[index] = true;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'dotdart generated SVG',
            ),
          );
        }
        _pump();
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
    for (final image in _images) {
      image?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_images);
}

class _DotdartSvgDecodedImage {
  _DotdartSvgDecodedImage(this.info, List<_DotdartSvgPattern> patterns)
    : source = Rect.fromLTWH(
        0,
        0,
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ) {
    for (final pattern in patterns) {
      final rect = pattern.singleImage;
      if (rect == null) continue;
      final shader = ImageShader(
        info.image,
        TileMode.decal,
        TileMode.decal,
        Float64List.fromList([
          rect.width / info.image.width,
          0,
          0,
          0,
          0,
          rect.height / info.image.height,
          0,
          0,
          0,
          0,
          1,
          0,
          rect.left,
          rect.top,
          0,
          1,
        ]),
        filterQuality: FilterQuality.low,
      );
      _shaders.add(shader);
      _shaderPaints[pattern] = Paint()..shader = shader;
    }
  }

  final ImageInfo info;
  final Rect source;
  final _shaders = <ImageShader>[];
  final _shaderPaints = <_DotdartSvgPattern, Paint>{};

  Paint? shaderPaint(_DotdartSvgPattern pattern) => _shaderPaints[pattern];

  void dispose() {
    for (final shader in _shaders) {
      shader.dispose();
    }
    info.dispose();
  }
}

class _DotdartSvgPattern {
  _DotdartSvgPattern({
    required Rect bounds,
    required bool objectBoundingBox,
    required double x,
    required double y,
    required double width,
    required double height,
    required double imageX,
    required double imageY,
    required double imageWidth,
    required double imageHeight,
  }) : _bounds = bounds {
    final sx = objectBoundingBox ? bounds.width : 1.0;
    final sy = objectBoundingBox ? bounds.height : 1.0;
    final ox = objectBoundingBox ? bounds.left : 0.0;
    final oy = objectBoundingBox ? bounds.top : 0.0;
    this.imageWidth = imageWidth * sx;
    this.imageHeight = imageHeight * sy;
    if (bounds.isEmpty) return;
    final tileWidth = width * sx;
    final tileHeight = height * sy;
    final firstX = ((bounds.left - ox - x * sx) / tileWidth).floor();
    final lastX = ((bounds.right - ox - x * sx) / tileWidth).ceil();
    final firstY = ((bounds.top - oy - y * sy) / tileHeight).floor();
    final lastY = ((bounds.bottom - oy - y * sy) / tileHeight).ceil();
    if ((lastX - firstX) * (lastY - firstY) > 4096) {
      throw FlutterError(
        'SVG image pattern exceeds 4096 visible tiles. Use a larger tile.',
      );
    }
    for (var row = firstY; row < lastY; row++) {
      for (var column = firstX; column < lastX; column++) {
        final dx = ox + column * tileWidth;
        final dy = oy + row * tileHeight;
        final tile = Rect.fromLTWH(
          dx + x * sx,
          dy + y * sy,
          tileWidth,
          tileHeight,
        );
        final image = Rect.fromLTWH(
          dx + (x + imageX) * sx,
          dy + (y + imageY) * sy,
          this.imageWidth,
          this.imageHeight,
        );
        final contained =
            tile.left <= image.left &&
            tile.top <= image.top &&
            tile.right >= image.right &&
            tile.bottom >= image.bottom;
        _tiles.add((clip: contained ? null : tile, image: image));
      }
    }
  }

  Rect? get singleImage => _tiles.length == 1 && _tiles.single.clip == null
      ? _tiles.single.image
      : null;

  late final double imageWidth;
  late final double imageHeight;
  final Rect _bounds;
  late final Path ovalClip = Path()..addOval(_bounds);
  final _tiles = <({Rect? clip, Rect image})>[];

  void paint(Canvas canvas, _DotdartSvgDecodedImage? info, Paint paint) {
    if (info == null) return;
    final image = info.info.image;
    for (final rects in _tiles) {
      final clip = rects.clip;
      if (clip != null) {
        canvas.save();
        canvas.clipRect(clip, doAntiAlias: false);
      }
      canvas.drawImageRect(image, info.source, rects.image, paint);
      if (clip != null) canvas.restore();
    }
  }
}

Color _dotdartApplyOpacity(Color color, double opacity) {
  if (opacity == 1) return color;
  return color.withValues(alpha: math.min(1, math.max(0, color.a * opacity)));
}

mixin _DotdartSvgSizing on StatelessWidget {
  double? get svgWidgetWidth;
  double? get svgWidgetHeight;
  double get svgNativeWidth;
  double get svgNativeHeight;
  double get svgViewBoxWidth;
  double get svgViewBoxHeight;
  bool get svgMaintainAspectRatio;

  Widget buildPainter({required double width, required double height});

  Size _defaultSizeFor(BoxConstraints constraints) {
    final aspect = svgViewBoxHeight / svgViewBoxWidth;
    var w = svgNativeWidth;
    if (constraints.hasBoundedWidth) {
      w = math.min(w, constraints.maxWidth);
    }
    if (constraints.hasBoundedHeight) {
      w = math.min(w, constraints.maxHeight / aspect);
    }
    return Size(w, w * aspect);
  }

  Size _resolveSize(double aspect) {
    if (svgWidgetWidth != null && svgWidgetHeight != null) {
      if (!svgMaintainAspectRatio) {
        return Size(svgWidgetWidth!, svgWidgetHeight!);
      }
      return svgWidgetWidth! >= svgWidgetHeight!
          ? Size(svgWidgetWidth!, svgWidgetWidth! * aspect)
          : Size(svgWidgetHeight! / aspect, svgWidgetHeight!);
    }

    final w = svgWidgetWidth ?? svgWidgetHeight! / aspect;
    return Size(w, svgWidgetHeight ?? w * aspect);
  }

  @override
  Widget build(BuildContext context) {
    final hasExplicitSize = svgWidgetWidth != null || svgWidgetHeight != null;

    if (!hasExplicitSize) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = _defaultSizeFor(constraints);
          return buildPainter(width: size.width, height: size.height);
        },
      );
    }

    final aspect = svgViewBoxHeight / svgViewBoxWidth;
    final size = _resolveSize(aspect);

    return OverflowBox(
      alignment: Alignment.topLeft,
      fit: OverflowBoxFit.deferToChild,
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: size.height,
      maxHeight: size.height,
      child: buildPainter(width: size.width, height: size.height),
    );
  }
}

/// Namespace for dotdart-generated widgets from `icons/`.
///
/// Call a method named after each asset to render it:
///
/// ```dart
/// $Icons.affineGeometry(<params>);
/// ```
/// ```dart
/// $Icons.cross(<params>);
/// ```
/// ```dart
/// $Icons.dropShadow(<params>);
/// ```
/// ```dart
/// $Icons.gradientPaints(<params>);
/// ```
/// ```dart
/// $Icons.imagePatterns(<params>);
/// ```
/// ```dart
/// $Icons.maskedArc(<params>);
/// ```
/// ```dart
/// $Icons.nestedGroups(<params>);
/// ```
abstract final class $Icons {
  $Icons._();

  /// Builds the `AffineGeometry` widget from `affineGeometry.svg`.
  static Widget affineGeometry({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
    Color? color1,
  }) => _AffineGeometry(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
    color1: color1,
  );

  /// Builds the `Cross` widget from `cross.svg`.
  static Widget cross({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
    Color? color1,
  }) => _Cross(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
    color1: color1,
  );

  /// Builds the `DropShadow` widget from `dropShadow.svg`.
  static Widget dropShadow({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
    Color? color1,
  }) => _DropShadow(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
    color1: color1,
  );

  /// Builds the `GradientPaints` widget from `gradientPaints.svg`.
  static Widget gradientPaints({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
  }) => _GradientPaints(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
  );

  /// Builds the `ImagePatterns` widget from `imagePatterns.svg`.
  static Widget imagePatterns({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
  }) => _ImagePatterns(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
  );

  /// Builds the `MaskedArc` widget from `maskedArc.svg`.
  static Widget maskedArc({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
    Color? color1,
  }) => _MaskedArc(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
    color1: color1,
  );

  /// Builds the `NestedGroups` widget from `nestedGroups.svg`.
  static Widget nestedGroups({
    Key? key,
    double? width,
    double? height,
    bool maintainAspectRatio = true,
    Color? backgroundColor,
    Color? outlineColor,
    Color? innerTextColor,
  }) => _NestedGroups(
    key: key,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
    backgroundColor: backgroundColor,
    outlineColor: outlineColor,
    innerTextColor: innerTextColor,
  );

  /// Builds the asset matching [fileName], or returns null if it is absent.
  ///
  /// Pass the original filename, including its extension and exact case.
  /// Directory paths and extensionless names do not match.
  /// [key] is forwarded to the generated widget. [width] and [height] are
  /// logical pixels and use the same sizing rules as the named accessor.
  /// All asset-specific options keep their defaults.
  static Widget? findByName(
    String fileName, {
    Key? key,
    double? width,
    double? height,
  }) => switch (fileName) {
    'affine_geometry.svg' => affineGeometry(
      key: key,
      width: width,
      height: height,
    ),
    'cross.svg' => cross(key: key, width: width, height: height),
    'drop_shadow.svg' => dropShadow(key: key, width: width, height: height),
    'gradient_paints.svg' => gradientPaints(
      key: key,
      width: width,
      height: height,
    ),
    'image_patterns.svg' => imagePatterns(
      key: key,
      width: width,
      height: height,
    ),
    'masked_arc.svg' => maskedArc(key: key, width: width, height: height),
    'nested_groups.svg' => nestedGroups(key: key, width: width, height: height),
    _ => null,
  };
}

/// A dotdart-generated SVG widget from `assets/icons/affine_geometry.svg`.
///
/// Renders a 100.0×100.0 SVG
/// on a viewBox of 0.0 0.0 100.0 100.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _AffineGeometry extends StatelessWidget with _DotdartSvgSizing {
  const _AffineGeometry({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
    this.color1,
  });

  static const double _svgWidth = 100;
  static const double _svgHeight = 100;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 100;
  static const double _viewBoxHeight = 100;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  /// Color 1 — defaults to 0xff000000.
  final Color? color1;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _AffineGeometry._svgWidth;

  @override
  double get svgNativeHeight => _AffineGeometry._svgHeight;

  @override
  double get svgViewBoxWidth => _AffineGeometry._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _AffineGeometry._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return SizedBox.fromSize(
      size: Size(width, height),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AffineGeometryPainter(
            color1: color1 ?? const Color(0xff000000),
          ),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class _AffineGeometryPainter extends CustomPainter {
  _AffineGeometryPainter({required this.color1});

  final Color color1;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  static final Float64List _transform0 = Float64List.fromList([
    0.765256464,
    0.0,
    0.0,
    0.0,
    0.0,
    0.765256464,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    2.730063589,
    2.347435357,
    0.0,
    1.0,
  ]);
  static final Float64List _transform1 = Float64List.fromList([
    1.0,
    0.0,
    0.0,
    0.0,
    0.9999999999999999,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    30.0,
    0.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform2 = Float64List.fromList([
    1.0,
    0.9999999999999999,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    60.0,
    0.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform3 = Float64List.fromList([
    2.0,
    0.0,
    0.0,
    0.0,
    0.0,
    2.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    30.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform4 = Float64List.fromList([
    1.0,
    0.0,
    0.0,
    0.0,
    0.9999999999999999,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform5 = Float64List.fromList([
    2.0,
    0.0,
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    30.0,
    30.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform6 = Float64List.fromList([
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    60.0,
    30.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform7 = Float64List.fromList([
    -1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    20.0,
    60.0,
    0.0,
    1.0,
  ]);
  static final Float64List _transform8 = Float64List.fromList([
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    30.0,
    60.0,
    0.0,
    1.0,
  ]);
  static const Rect _rect0 = Rect.fromLTWH(0, 0, 10, 10);

  static const Rect _rect1 = Rect.fromLTWH(0, 2, 8, 8);

  static const Rect _rect2 = Rect.fromLTWH(2, 0, 8, 8);

  static const Rect _rect3 = Rect.fromLTWH(2, 2, 4, 4);

  static final Path __path0 = Path()
    ..moveTo(2, 4)
    ..lineTo(10, 4);

  static const Rect _rect4 = Rect.fromLTWH(0, 0, 20, 20);

  static const Rect _rect5 = Rect.fromLTWH(2, 2, 6, 6);

  static const Rect _rect6 = Rect.fromLTWH(0, 0, 10, 10);

  static final Path __clip0 = _buildClip0();

  static Path _buildClip0() {
    final path = Path();
    final clipShape0 = Path()..addRect(const Rect.fromLTWH(0, 0, 8, 8));
    path.addPath(
      clipShape0,
      Offset.zero,
      matrix4: Float64List.fromList([
        1.0,
        0.0,
        0.0,
        0.0,
        0.9999999999999999,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        2.0,
        2.0,
        0.0,
        1.0,
      ]),
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _AffineGeometry._viewBoxWidth;
    final scaleY = size.height / _AffineGeometry._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_AffineGeometry._viewBoxMinX, -_AffineGeometry._viewBoxMinY);

    canvas.save();
    canvas.transform(_transform0);
    canvas.drawRect(_rect0, _fillPaint..color = color1);
    canvas.restore();
    canvas.save();
    canvas.transform(_transform1);
    canvas.drawRect(_rect1, _fillPaint..color = color1);
    canvas.restore();
    canvas.save();
    canvas.transform(_transform2);
    canvas.drawRect(_rect2, _fillPaint..color = color1);
    canvas.restore();
    canvas.save();
    canvas.transform(_transform3);
    canvas.save();
    canvas.transform(_transform4);
    canvas.drawRect(_rect3, _fillPaint..color = color1);
    canvas.restore();
    canvas.restore();
    canvas.save();
    canvas.transform(_transform5);
    canvas.drawPath(
      __path0,
      _strokePaint
        ..color = color1
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();
    canvas.save();
    canvas.transform(_transform6);
    canvas.clipPath(__clip0);
    canvas.drawRect(_rect4, _fillPaint..color = color1);
    canvas.restore();
    canvas.save();
    canvas.transform(_transform7);
    canvas.drawRect(_rect5, _fillPaint..color = color1);
    canvas.restore();
    canvas.save();
    canvas.transform(_transform8);
    canvas.drawRect(_rect6, _fillPaint..color = color1);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AffineGeometryPainter oldDelegate) {
    return oldDelegate.color1 != color1;
  }
}

/// A dotdart-generated SVG widget from `assets/icons/cross.svg`.
///
/// Renders a 24.0×24.0 SVG
/// on a viewBox of 0.0 0.0 24.0 24.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _Cross extends StatelessWidget with _DotdartSvgSizing {
  const _Cross({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
    this.color1,
  });

  static const double _svgWidth = 24;
  static const double _svgHeight = 24;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 24;
  static const double _viewBoxHeight = 24;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  /// Color 1 — defaults to 0xff000000.
  final Color? color1;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _Cross._svgWidth;

  @override
  double get svgNativeHeight => _Cross._svgHeight;

  @override
  double get svgViewBoxWidth => _Cross._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _Cross._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return SizedBox.fromSize(
      size: Size(width, height),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CrossPainter(color1: color1 ?? const Color(0xff000000)),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter({required this.color1});

  final Color color1;

  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  static final Path __path0 = Path()
    ..moveTo(0.75, 0.75)
    ..lineTo(23.25, 23.25)
    ..moveTo(23.25, 0.75)
    ..lineTo(0.75, 23.25);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _Cross._viewBoxWidth;
    final scaleY = size.height / _Cross._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_Cross._viewBoxMinX, -_Cross._viewBoxMinY);

    canvas.drawPath(
      __path0,
      _strokePaint
        ..color = color1
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) {
    return oldDelegate.color1 != color1;
  }
}

/// A dotdart-generated SVG widget from `assets/icons/drop_shadow.svg`.
///
/// Renders a 42.0×42.0 SVG
/// on a viewBox of 0.0 0.0 42.0 42.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _DropShadow extends StatelessWidget with _DotdartSvgSizing {
  const _DropShadow({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
    this.color1,
  });

  static const double _svgWidth = 42;
  static const double _svgHeight = 42;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 42;
  static const double _viewBoxHeight = 42;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  /// Color 1 — defaults to 0xff42c552.
  final Color? color1;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _DropShadow._svgWidth;

  @override
  double get svgNativeHeight => _DropShadow._svgHeight;

  @override
  double get svgViewBoxWidth => _DropShadow._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _DropShadow._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return SizedBox.fromSize(
      size: Size(width, height),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DropShadowPainter(
            color1: color1 ?? const Color(0xff42c552),
          ),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class _DropShadowPainter extends CustomPainter {
  _DropShadowPainter({required this.color1});

  final Color color1;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static const Rect _shadowBounds0 = Rect.fromLTWH(
    0.00380427,
    -0.000631422,
    41.2346,
    41.3049,
  );
  final Paint _shadowColor0 = Paint()
    ..colorFilter = const ColorFilter.matrix([
      0,
      0,
      0,
      0,
      0.0,
      0,
      0,
      0,
      0,
      0.0,
      0,
      0,
      0,
      0,
      0.0,
      0,
      0,
      0,
      0.68,
      0,
    ]);
  final Paint _shadowBlur0 = Paint()
    ..imageFilter = ImageFilter.blur(
      sigmaX: 0.419973,
      sigmaY: 0.419973,
      tileMode: TileMode.decal,
    );
  final Paint _shadowAlpha0 = Paint()
    ..colorFilter = const ColorFilter.matrix([
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      127.0,
      0,
    ]);
  final Paint _shadowOut0 = Paint()
    ..blendMode = BlendMode.dstOut
    ..colorFilter = const ColorFilter.matrix([
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      127.0,
      0,
    ]);
  static final Path __path0 = Path()
    ..moveTo(8, 8)
    ..lineTo(32, 8)
    ..lineTo(32, 32)
    ..lineTo(8, 32)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _DropShadow._viewBoxWidth;
    final scaleY = size.height / _DropShadow._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_DropShadow._viewBoxMinX, -_DropShadow._viewBoxMinY);

    canvas.save();
    canvas.clipRect(_shadowBounds0);
    canvas.saveLayer(_shadowBounds0, _shadowColor0);
    canvas.saveLayer(_shadowBounds0, _shadowBlur0);
    canvas.translate(0, 0.3706);
    canvas.clipRect(_shadowBounds0);
    canvas.saveLayer(_shadowBounds0, _shadowAlpha0);
    canvas.drawPath(__path0, _fillPaint..color = color1);
    canvas.restore();
    canvas.restore();
    canvas.saveLayer(_shadowBounds0, _shadowOut0);
    canvas.drawPath(__path0, _fillPaint..color = color1);
    canvas.restore();
    canvas.restore();
    canvas.drawPath(__path0, _fillPaint..color = color1);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DropShadowPainter oldDelegate) {
    return oldDelegate.color1 != color1;
  }
}

/// A dotdart-generated SVG widget from `assets/icons/gradient_paints.svg`.
///
/// Renders a 100.0×100.0 SVG
/// on a viewBox of 0.0 0.0 100.0 100.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _GradientPaints extends StatelessWidget with _DotdartSvgSizing {
  const _GradientPaints({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
  });

  static const double _svgWidth = 100;
  static const double _svgHeight = 100;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 100;
  static const double _viewBoxHeight = 100;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _GradientPaints._svgWidth;

  @override
  double get svgNativeHeight => _GradientPaints._svgHeight;

  @override
  double get svgViewBoxWidth => _GradientPaints._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _GradientPaints._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return SizedBox.fromSize(
      size: Size(width, height),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GradientPaintsPainter(),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class _GradientPaintsPainter extends CustomPainter {
  _GradientPaintsPainter();

  static const Rect _rect0 = Rect.fromLTWH(0, 0, 100, 100);

  static final Paint _gradient0 = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.center,
      end: Alignment(100, 0),
      colors: [Color(0xffff0000), Color(0xff0000ff)],
      stops: [0.0, 1.0],
    ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _GradientPaints._viewBoxWidth;
    final scaleY = size.height / _GradientPaints._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_GradientPaints._viewBoxMinX, -_GradientPaints._viewBoxMinY);

    canvas.drawRect(
      _rect0,
      (_gradient0
        ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientPaintsPainter oldDelegate) {
    return false;
  }
}

/// A dotdart-generated SVG widget from `assets/icons/image_patterns.svg`.
///
/// Renders a 100.0×100.0 SVG
/// on a viewBox of 0.0 0.0 100.0 100.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _ImagePatterns extends StatelessWidget with _DotdartSvgSizing {
  const _ImagePatterns({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
  });

  static const double _svgWidth = 100;
  static const double _svgHeight = 100;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 100;
  static const double _viewBoxHeight = 100;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _ImagePatterns._svgWidth;

  @override
  double get svgNativeHeight => _ImagePatterns._svgHeight;

  @override
  double get svgViewBoxWidth => _ImagePatterns._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _ImagePatterns._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return Builder(
      builder: (context) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        return _DotdartSvgImages(
          patterns: _ImagePatternsPainter._patternDefinitions,
          providers: [
            ResizeImage(
              _ImagePatternsPainter._image0,
              width: math.min(
                128,
                math.max(
                  1,
                  (width /
                          _viewBoxWidth *
                          _ImagePatternsPainter._decodeWidth0 *
                          ratio)
                      .ceil(),
                ),
              ),
              height: math.min(
                128,
                math.max(
                  1,
                  (height /
                          _viewBoxHeight *
                          _ImagePatternsPainter._decodeHeight0 *
                          ratio)
                      .ceil(),
                ),
              ),
            ),
          ],
          builder: (images) => SizedBox.fromSize(
            size: Size(width, height),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ImagePatternsPainter(images: images),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImagePatternsPainter extends CustomPainter {
  _ImagePatternsPainter({required this.images});

  final List<_DotdartSvgDecodedImage?> images;

  static final Path __path0 = Path()
    ..moveTo(0, 0)
    ..lineTo(100, 0)
    ..lineTo(100, 100)
    ..lineTo(0, 100)
    ..close();

  static final MemoryImage _image0 = MemoryImage(
    Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      128,
      0,
      0,
      0,
      128,
      8,
      6,
      0,
      0,
      0,
      195,
      62,
      97,
      203,
      0,
      0,
      1,
      94,
      73,
      68,
      65,
      84,
      120,
      156,
      237,
      210,
      193,
      9,
      0,
      48,
      12,
      196,
      176,
      236,
      191,
      116,
      186,
      68,
      161,
      5,
      139,
      224,
      255,
      17,
      52,
      59,
      179,
      229,
      62,
      152,
      240,
      182,
      247,
      11,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      62,
      152,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      112,
      229,
      5,
      233,
      219,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      239,
      0,
      234,
      72,
      120,
      98,
      125,
      136,
      2,
      118,
      0,
      0,
      0,
      0,
      73,
      69,
      78,
      68,
      174,
      66,
      96,
      130,
    ]),
  );
  static final _pattern0Geometry0 = _DotdartSvgPattern(
    bounds: __path0.getBounds(),
    objectBoundingBox: false,
    x: -25,
    y: -25,
    width: 100,
    height: 100,
    imageX: 0,
    imageY: 0,
    imageWidth: 100,
    imageHeight: 100,
  );
  static final double _decodeWidth0 = _pattern0Geometry0.imageWidth * 1;
  static final double _decodeHeight0 = _pattern0Geometry0.imageHeight * 1;
  static final List<List<_DotdartSvgPattern>> _patternDefinitions = [
    [_pattern0Geometry0],
  ];
  static final Paint _patternPaint = Paint()..filterQuality = FilterQuality.low;
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _ImagePatterns._viewBoxWidth;
    final scaleY = size.height / _ImagePatterns._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_ImagePatterns._viewBoxMinX, -_ImagePatterns._viewBoxMinY);

    if (images[0]?.shaderPaint(_pattern0Geometry0) case final patternPaint?) {
      canvas.drawPath(
        __path0,
        patternPaint
          ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
      );
    } else {
      canvas.save();
      canvas.clipPath(__path0);
      _pattern0Geometry0.paint(
        canvas,
        images[0],
        _patternPaint
          ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ImagePatternsPainter oldDelegate) {
    return !identical(images, oldDelegate.images);
  }
}

/// A dotdart-generated SVG widget from `assets/icons/masked_arc.svg`.
///
/// Renders a 100.0×100.0 SVG
/// on a viewBox of 0.0 0.0 100.0 100.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _MaskedArc extends StatelessWidget with _DotdartSvgSizing {
  const _MaskedArc({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
    this.color1,
  });

  static const double _svgWidth = 100;
  static const double _svgHeight = 100;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 100;
  static const double _viewBoxHeight = 100;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  /// Color 1 — defaults to 0xff00ff00.
  final Color? color1;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _MaskedArc._svgWidth;

  @override
  double get svgNativeHeight => _MaskedArc._svgHeight;

  @override
  double get svgViewBoxWidth => _MaskedArc._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _MaskedArc._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return Builder(
      builder: (context) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        return _DotdartSvgImages(
          patterns: _MaskedArcPainter._patternDefinitions,
          providers: [
            ResizeImage(
              _MaskedArcPainter._image0,
              width: math.min(
                128,
                math.max(
                  1,
                  (width /
                          _viewBoxWidth *
                          _MaskedArcPainter._decodeWidth0 *
                          ratio)
                      .ceil(),
                ),
              ),
              height: math.min(
                128,
                math.max(
                  1,
                  (height /
                          _viewBoxHeight *
                          _MaskedArcPainter._decodeHeight0 *
                          ratio)
                      .ceil(),
                ),
              ),
            ),
          ],
          builder: (images) => SizedBox.fromSize(
            size: Size(width, height),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _MaskedArcPainter(
                  color1: color1 ?? const Color(0xff00ff00),
                  images: images,
                ),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaskedArcPainter extends CustomPainter {
  _MaskedArcPainter({required this.images, required this.color1});

  final Color color1;
  final List<_DotdartSvgDecodedImage?> images;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static const Rect _rect0 = Rect.fromLTWH(0, 0, 100, 100);

  static final Path __path0 = Path()
    ..moveTo(0, 0)
    ..lineTo(100, 0)
    ..lineTo(100, 100)
    ..lineTo(0, 100)
    ..close();

  static final Path __clip0 = Path()
    ..moveTo(50, 0)
    ..arcToPoint(
      const Offset(100, 50),
      radius: const Radius.elliptical(50, 50),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..lineTo(100, 100)
    ..lineTo(0, 100)
    ..lineTo(0, 50)
    ..arcToPoint(
      const Offset(50, 0),
      radius: const Radius.elliptical(50, 50),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..close();

  static final Path _maskedPattern0 = Path.combine(
    PathOperation.intersect,
    Path.combine(PathOperation.intersect, __clip0, __path0),
    Path()..addRect(const Rect.fromLTWH(0, 0, 100, 100)),
  );
  static final MemoryImage _image0 = MemoryImage(
    Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      128,
      0,
      0,
      0,
      128,
      8,
      6,
      0,
      0,
      0,
      195,
      62,
      97,
      203,
      0,
      0,
      1,
      94,
      73,
      68,
      65,
      84,
      120,
      156,
      237,
      210,
      193,
      9,
      0,
      48,
      12,
      196,
      176,
      236,
      191,
      116,
      186,
      68,
      161,
      5,
      139,
      224,
      255,
      17,
      52,
      59,
      179,
      229,
      62,
      152,
      240,
      182,
      247,
      11,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      62,
      152,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      112,
      229,
      5,
      233,
      219,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      15,
      128,
      120,
      0,
      196,
      3,
      32,
      30,
      0,
      241,
      0,
      136,
      7,
      64,
      60,
      0,
      226,
      1,
      16,
      239,
      0,
      234,
      72,
      120,
      98,
      125,
      136,
      2,
      118,
      0,
      0,
      0,
      0,
      73,
      69,
      78,
      68,
      174,
      66,
      96,
      130,
    ]),
  );
  static final _pattern0Geometry1 = _DotdartSvgPattern(
    bounds: __path0.getBounds(),
    objectBoundingBox: true,
    x: 0,
    y: 0,
    width: 1,
    height: 1,
    imageX: 0,
    imageY: 0,
    imageWidth: 1,
    imageHeight: 1,
  );
  static final double _decodeWidth0 = _pattern0Geometry1.imageWidth * 1;
  static final double _decodeHeight0 = _pattern0Geometry1.imageHeight * 1;
  static final List<List<_DotdartSvgPattern>> _patternDefinitions = [
    [_pattern0Geometry1],
  ];
  static final Paint _patternPaint = Paint()..filterQuality = FilterQuality.low;
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _MaskedArc._viewBoxWidth;
    final scaleY = size.height / _MaskedArc._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_MaskedArc._viewBoxMinX, -_MaskedArc._viewBoxMinY);

    canvas.drawRect(_rect0, _fillPaint..color = color1);
    if (images[0]?.shaderPaint(_pattern0Geometry1) case final maskedPaint?) {
      canvas.drawPath(
        _maskedPattern0,
        maskedPaint
          ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
      );
    } else {
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(0, 0, 100, 100));
      canvas.clipPath(__clip0);
      if (images[0]?.shaderPaint(_pattern0Geometry1) case final patternPaint?) {
        canvas.drawPath(
          __path0,
          patternPaint
            ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );
      } else {
        canvas.save();
        canvas.clipPath(__path0);
        _pattern0Geometry1.paint(
          canvas,
          images[0],
          _patternPaint
            ..color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );
        canvas.restore();
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaskedArcPainter oldDelegate) {
    return !identical(images, oldDelegate.images) ||
        oldDelegate.color1 != color1;
  }
}

/// A dotdart-generated SVG widget from `assets/icons/nested_groups.svg`.
///
/// Renders a 40.0×40.0 SVG
/// on a viewBox of 0.0 0.0 40.0 40.0.
/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].
class _NestedGroups extends StatelessWidget with _DotdartSvgSizing {
  const _NestedGroups({
    super.key,
    this.width,
    this.height,
    this.maintainAspectRatio = true,
    this.backgroundColor,
    this.outlineColor,
    this.innerTextColor,
  });

  static const double _svgWidth = 40;
  static const double _svgHeight = 40;
  static const double _viewBoxMinX = 0;
  static const double _viewBoxMinY = 0;
  static const double _viewBoxWidth = 40;
  static const double _viewBoxHeight = 40;

  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// When true (default), keeps the native aspect ratio using the larger requested value as the reference. When false, both dimensions are applied as-is and the asset may distort.
  final bool maintainAspectRatio;

  /// Color from SVG id `background` — defaults to 0xff0000ff.
  final Color? backgroundColor;

  /// Color from SVG id `outline` — defaults to 0xffff0000.
  final Color? outlineColor;

  /// Color from SVG id `inner_text` — defaults to 0xff00ff00.
  final Color? innerTextColor;

  @override
  double? get svgWidgetWidth => width;

  @override
  double? get svgWidgetHeight => height;

  @override
  bool get svgMaintainAspectRatio => maintainAspectRatio;

  @override
  double get svgNativeWidth => _NestedGroups._svgWidth;

  @override
  double get svgNativeHeight => _NestedGroups._svgHeight;

  @override
  double get svgViewBoxWidth => _NestedGroups._viewBoxWidth;

  @override
  double get svgViewBoxHeight => _NestedGroups._viewBoxHeight;

  @override
  Widget buildPainter({required double width, required double height}) {
    return SizedBox.fromSize(
      size: Size(width, height),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _NestedGroupsPainter(
            backgroundColor: backgroundColor ?? const Color(0xff0000ff),
            outlineColor: outlineColor ?? const Color(0xffff0000),
            innerTextColor: innerTextColor ?? const Color(0xff00ff00),
          ),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class _NestedGroupsPainter extends CustomPainter {
  _NestedGroupsPainter({
    required this.backgroundColor,
    required this.outlineColor,
    required this.innerTextColor,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color innerTextColor;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static const Rect _rect0 = Rect.fromLTWH(0, 0, 40, 40);

  static const Rect _rect1 = Rect.fromLTWH(0, 0, 32, 32);

  static const Rect _rect2 = Rect.fromLTWH(0, 0, 16, 16);

  static final Path __clip0 = Path()
    ..addRect(const Rect.fromLTWH(0, 0, 20, 20));

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _NestedGroups._viewBoxWidth;
    final scaleY = size.height / _NestedGroups._viewBoxHeight;
    canvas
      ..save()
      ..scale(scaleX, scaleY)
      ..translate(-_NestedGroups._viewBoxMinX, -_NestedGroups._viewBoxMinY);

    canvas.drawRect(_rect0, _fillPaint..color = backgroundColor);
    canvas.save();
    canvas.translate(4, 4);
    canvas.clipPath(__clip0);
    canvas.drawRect(_rect1, _fillPaint..color = outlineColor);
    canvas.save();
    canvas.translate(8, 8);
    canvas.drawRect(
      _rect2,
      _fillPaint..color = _dotdartApplyOpacity(innerTextColor, 0.5),
    );
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NestedGroupsPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.innerTextColor != innerTextColor;
  }
}
