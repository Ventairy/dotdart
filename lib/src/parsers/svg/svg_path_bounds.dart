import 'dart:math' as math;

import '../../models/svg_element.dart';
import '../lottie_parser.dart' show DotdartUnsupportedFeatureException;

/// Computes tight bounds for SVG lines and Bezier curves during generation.
class SvgPathBounds {
  SvgPathBounds._();

  double _left = double.infinity;
  double _top = double.infinity;
  double _right = double.negativeInfinity;
  double _bottom = double.negativeInfinity;
  double _x = 0;
  double _y = 0;
  double _startX = 0;
  double _startY = 0;

  /// Returns exact geometric bounds without Flutter path construction.
  static ({double left, double top, double width, double height}) calculate(SvgPath path) {
    final bounds = SvgPathBounds._();
    path.commands.forEach(bounds._includeCommand);
    if (bounds._left == double.infinity) return (left: 0, top: 0, width: 0, height: 0);
    final width = bounds._right - bounds._left;
    final height = bounds._bottom - bounds._top;
    if (!width.isFinite || !height.isFinite) {
      throw const FormatException('SVG path bounds must remain finite. Reduce the path coordinates.');
    }
    return (left: bounds._left, top: bounds._top, width: width, height: height);
  }

  void _includeCommand(SvgPathCommand command) {
    switch (command) {
      case SvgMoveTo(:final x, :final y):
        _startX = x;
        _startY = y;
        _x = x;
        _y = y;
        _include(x: x, y: y);
      case SvgLineTo(:final x, :final y):
        _include(x: x, y: y);
        _x = x;
        _y = y;
      case SvgCubicTo():
        for (final t in [
          ..._cubicExtrema(start: _x, control1: command.x1, control2: command.x2, end: command.x),
          ..._cubicExtrema(start: _y, control1: command.y1, control2: command.y2, end: command.y),
        ]) {
          _include(
            x: _cubicValue(start: _x, control1: command.x1, control2: command.x2, end: command.x, t: t),
            y: _cubicValue(start: _y, control1: command.y1, control2: command.y2, end: command.y, t: t),
          );
        }
        _include(x: command.x, y: command.y);
        _x = command.x;
        _y = command.y;
      case SvgQuadTo():
        for (final t in [
          ..._quadraticExtrema(start: _x, control: command.x1, end: command.x),
          ..._quadraticExtrema(start: _y, control: command.y1, end: command.y),
        ]) {
          _include(
            x: _quadraticValue(start: _x, control: command.x1, end: command.x, t: t),
            y: _quadraticValue(start: _y, control: command.y1, end: command.y, t: t),
          );
        }
        _include(x: command.x, y: command.y);
        _x = command.x;
        _y = command.y;
      case SvgClosePath():
        _x = _startX;
        _y = _startY;
      case SvgArcTo():
        throw const DotdartUnsupportedFeatureException(
          'Image patterns using shape bounds cannot fill arc paths yet. '
          'Convert arcs to cubic curves, or use userSpaceOnUse for both pattern unit attributes.',
        );
    }
  }

  void _include({required double x, required double y}) {
    if (!x.isFinite || !y.isFinite) throw const FormatException('SVG path bounds require finite coordinates.');
    _left = math.min(_left, x);
    _right = math.max(_right, x);
    _top = math.min(_top, y);
    _bottom = math.max(_bottom, y);
  }

  List<double> _cubicExtrema({
    required double start,
    required double control1,
    required double control2,
    required double end,
  }) {
    final a = -start + 3 * control1 - 3 * control2 + end;
    final b = 2 * (start - 2 * control1 + control2);
    final c = control1 - start;
    if (![a, b, c].every((value) => value.isFinite)) {
      throw const FormatException('SVG curve bounds must remain finite. Reduce the path coordinates.');
    }
    if (a == 0) return b == 0 ? const [] : _interiorRoots([-c / b]);
    final discriminant = b * b - 4 * a * c;
    if (!discriminant.isFinite) {
      throw const FormatException('SVG curve bounds must remain finite. Reduce the path coordinates.');
    }
    if (discriminant < 0) return const [];
    // Avoid subtracting nearly equal values when one derivative root is small.
    final root = math.sqrt(discriminant);
    final q = -0.5 * (b + (b < 0 ? -root : root));
    return q == 0 ? _interiorRoots([-b / (2 * a)]) : _interiorRoots([q / a, c / q]);
  }

  List<double> _quadraticExtrema({required double start, required double control, required double end}) {
    final denominator = start - 2 * control + end;
    if (!denominator.isFinite) {
      throw const FormatException('SVG curve bounds must remain finite. Reduce the path coordinates.');
    }
    return denominator == 0 ? const [] : _interiorRoots([(start - control) / denominator]);
  }

  List<double> _interiorRoots(List<double> roots) => [
    for (final root in roots)
      if (root > 0 && root < 1) root,
  ];

  double _cubicValue({
    required double start,
    required double control1,
    required double control2,
    required double end,
    required double t,
  }) {
    final u = 1 - t;
    return u * u * u * start + 3 * u * u * t * control1 + 3 * u * t * t * control2 + t * t * t * end;
  }

  double _quadraticValue({required double start, required double control, required double end, required double t}) {
    final u = 1 - t;
    return u * u * start + 2 * u * t * control + t * t * end;
  }
}
