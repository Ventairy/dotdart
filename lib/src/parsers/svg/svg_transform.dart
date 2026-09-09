import 'dart:math' as math;

import '../../models/svg_element.dart';
import '../lottie_parser.dart' show DotdartUnsupportedFeatureException;

/// Parses SVG translate, scale, rotate, matrix, skewX, and skewY operations.
class SvgTransform {
  static final _function = RegExp(r'([A-Za-z]+)\s*\(([^()]*)\)');
  static final _number = RegExp(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?');
  static final _separator = RegExp(r'\s*,?\s*');

  /// Parses a complete transform list, retaining SVG source order.
  static List<SvgTransformOp> parse(String transform) {
    final source = transform.trim();
    final operations = <SvgTransformOp>[];
    var offset = 0;
    while (offset < source.length) {
      final match = _function.matchAsPrefix(source, offset);
      if (match == null) throw FormatException('Invalid SVG transform syntax near "${source.substring(offset)}".');
      final name = match.group(1)!;
      final arguments = _parseArguments(match.group(2)!);
      operations.add(_operation(name: name, arguments: arguments));
      offset = match.end;
      if (offset == source.length) break;
      final separator = _separator.matchAsPrefix(source, offset)!;
      if (separator.end == offset || separator.end == source.length) {
        throw const FormatException('Separate SVG transform functions with whitespace or a comma.');
      }
      offset = separator.end;
    }
    return List.unmodifiable(operations);
  }

  static List<double> _parseArguments(String source) {
    final text = source.trim();
    final arguments = <double>[];
    var offset = 0;
    while (offset < text.length) {
      final match = _number.matchAsPrefix(text, offset);
      if (match == null) throw FormatException('Invalid SVG transform number near "${text.substring(offset)}".');
      final value = double.parse(match.group(0)!);
      if (!value.isFinite) throw const FormatException('SVG transform numbers must be finite.');
      arguments.add(value);
      offset = match.end;
      if (offset == text.length) break;
      final separator = _separator.matchAsPrefix(text, offset)!;
      if (separator.end == offset || separator.end == text.length) {
        throw const FormatException('Separate SVG transform numbers with whitespace or a comma.');
      }
      offset = separator.end;
    }
    return arguments;
  }

  static SvgTransformOp _operation({required String name, required List<double> arguments}) {
    final counts = switch (name) {
      'translate' || 'scale' => const [1, 2],
      'rotate' => const [1, 3],
      'matrix' => const [6],
      'skewX' || 'skewY' => const [1],
      _ => throw DotdartUnsupportedFeatureException('Unknown SVG transform function "$name".'),
    };
    if (!counts.contains(arguments.length)) {
      throw FormatException('SVG $name() requires ${counts.join(' or ')} numbers; received ${arguments.length}.');
    }
    switch (name) {
      case 'translate':
        return SvgTranslate(tx: arguments[0], ty: arguments.length == 2 ? arguments[1] : 0);
      case 'scale':
        return SvgScale(sx: arguments[0], sy: arguments.length == 2 ? arguments[1] : arguments[0]);
      case 'rotate':
        return SvgRotate(
          angle: arguments[0],
          cx: arguments.length == 3 ? arguments[1] : null,
          cy: arguments.length == 3 ? arguments[2] : null,
        );
      case 'matrix':
        return SvgMatrix(
          a: arguments[0],
          b: arguments[1],
          c: arguments[2],
          d: arguments[3],
          e: arguments[4],
          f: arguments[5],
        );
      case 'skewX':
      case 'skewY':
        final angle = arguments[0].remainder(180);
        if (angle.abs() == 90) throw FormatException('SVG $name() is undefined at odd multiples of 90 degrees.');
        final skew = math.tan(angle * (math.pi / 180));
        if (!skew.isFinite) throw FormatException('SVG $name() must produce a finite skew.');
        return SvgMatrix(a: 1, b: name == 'skewY' ? skew : 0, c: name == 'skewX' ? skew : 0, d: 1, e: 0, f: 0);
      default:
        throw StateError('Unvalidated SVG transform "$name".');
    }
  }
}
