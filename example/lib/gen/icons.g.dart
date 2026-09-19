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

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

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

  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

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

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

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

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

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
