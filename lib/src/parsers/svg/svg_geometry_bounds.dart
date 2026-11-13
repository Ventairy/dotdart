import 'dart:math' as math;

import '../../models/svg_element.dart';

/// Computes conservative build-time bounds for limiting image-pattern work.
class SvgGeometryBounds {
  SvgGeometryBounds._();

  static (double, double, double, double) of(SvgElement element) {
    final points = <(double, double)>[];
    switch (element) {
      case SvgPath(:final commands):
        var x = 0.0;
        var y = 0.0;
        var startX = 0.0;
        var startY = 0.0;
        for (final command in commands) {
          switch (command) {
            case SvgMoveTo(:final x, :final y):
              startX = x;
              startY = y;
              points.add((x, y));
            case SvgLineTo(:final x, :final y):
              points.add((x, y));
            case SvgCubicTo(:final x1, :final y1, :final x2, :final y2, :final x, :final y):
              points.addAll([(x1, y1), (x2, y2), (x, y)]);
            case SvgQuadTo(:final x1, :final y1, :final x, :final y):
              points.addAll([(x1, y1), (x, y)]);
            case SvgArcTo(:final rx, :final ry, x: final endX, y: final endY):
              final dx = endX - x;
              final dy = endY - y;
              final correction = math.max(1, math.sqrt(dx * dx + dy * dy) / (2 * math.min(rx, ry)));
              final radius = math.sqrt(rx * rx + ry * ry) * correction * 2;
              final midX = (x + endX) / 2;
              final midY = (y + endY) / 2;
              points.addAll([(midX - radius, midY - radius), (midX + radius, midY + radius), (endX, endY)]);
            case SvgClosePath():
              points.add((startX, startY));
          }
          x = points.last.$1;
          y = points.last.$2;
        }
      case SvgRect(:final x, :final y, :final width, :final height):
        return (x, y, x + width, y + height);
      case SvgCircle(:final cx, :final cy, :final r):
        return (cx - r, cy - r, cx + r, cy + r);
      case SvgEllipse(:final cx, :final cy, :final rx, :final ry):
        return (cx - rx, cy - ry, cx + rx, cy + ry);
      case SvgLine(:final x1, :final y1, :final x2, :final y2):
        points.addAll([(x1, y1), (x2, y2)]);
      case SvgPolyline(:final points):
        return _pointsBounds(points);
      case SvgPolygon(:final points):
        return _pointsBounds(points);
      case SvgGroup():
        throw ArgumentError('Pattern bounds require a drawable shape.');
    }
    return _pointsBounds(points);
  }

  static (double, double, double, double) _pointsBounds(List<(double, double)> points) {
    if (points.isEmpty) return (0, 0, 0, 0);
    var left = points.first.$1;
    var top = points.first.$2;
    var right = left;
    var bottom = top;
    for (final (x, y) in points) {
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
    return (left, top, right, bottom);
  }
}
