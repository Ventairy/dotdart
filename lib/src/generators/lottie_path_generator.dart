// Repeated writes mirror generated source statements.
// ignore_for_file: cascade_invocations

import '../models/lottie_keyframe.dart';
import '../models/lottie_shape.dart';

/// Emits specialized arithmetic and reusable storage for one animated path.
class LottiePathGenerator {
  const LottiePathGenerator();

  /// Writes a path evaluator named [name] that accepts composition-local frames.
  void write(
    StringBuffer output, {
    required String name,
    required LottiePath path,
    required String Function(LottieScalarKeyframe) easing,
    bool trackRevision = false,
  }) {
    output.writeln('  final Path ${name}Value = Path();');
    output.writeln('  double ${name}Frame = double.nan;');
    output.writeln('  double ${name}T = double.nan;');
    output.writeln('  int ${name}Segment = -1;');
    if (trackRevision) output.writeln('  int ${name}Revision = 0;');
    output.writeln();
    output.writeln('  Path $name(double frame) {');
    output.writeln('    if (frame == ${name}Frame) return ${name}Value;');
    output.writeln('    ${name}Frame = frame;');
    final frames = path.keyframes;
    for (var index = 0; index < frames.length; index++) {
      final current = frames[index];
      final last = index == frames.length - 1;
      if (!last) output.writeln('    if (frame < ${_number(frames[index + 1].timing.time)}) {');
      final constant = last || current.timing.hold || current.start.hasSameGeometry(current.end);
      if (constant) {
        output.writeln('      const t = 0.0;');
      } else {
        final time = current.timing.time;
        final duration = frames[index + 1].timing.time - time;
        final offset = time == 0 ? 'frame' : '(frame - ${_number(time)})';
        final expression = '$offset / ${_number(duration)}';
        if (index == 0) {
          output.writeln('      var progress = 0.0;');
          output.writeln('      if (frame > ${_number(time)}) progress = $expression;');
        } else {
          output.writeln('      final progress = $expression;');
        }
        output.writeln('      final t = ${easing(current.timing)};');
      }
      output.writeln('      if (${name}Segment == $index && ${name}T == t) return ${name}Value;');
      output.writeln('      ${name}Segment = $index;');
      output.writeln('      ${name}T = t;');
      if (trackRevision) output.writeln('      ${name}Revision++;');
      output.writeln('      ${name}Value');
      output.writeln('        ..reset()');
      final start = _coordinates(current.start);
      final end = constant ? start : _coordinates(current.end);
      output.writeln('        ..moveTo(${_coordinate(start[0], end[0])}, ${_coordinate(start[1], end[1])})');
      for (var offset = 2; offset < start.length; offset += 6) {
        output.writeln(
          '        ..cubicTo(${[
            for (var axis = offset; axis < offset + 6; axis++) _coordinate(start[axis], end[axis]),
          ].join(', ')})',
        );
      }
      if (path.closed) output.writeln('        ..close()');
      output.writeln('      ;');
      output.writeln('      return ${name}Value;');
      if (!last) output.writeln('    }');
    }
    output.writeln('  }');
    output.writeln();
  }

  List<double> _coordinates(LottiePath pose) {
    final vertices = pose.vertices;
    return [
      ...vertices.first,
      for (var index = 1; index < vertices.length + (pose.closed ? 1 : 0); index++) ...[
        vertices[index - 1][0] + pose.outTangents[index - 1][0],
        vertices[index - 1][1] + pose.outTangents[index - 1][1],
        vertices[index % vertices.length][0] + pose.inTangents[index % vertices.length][0],
        vertices[index % vertices.length][1] + pose.inTangents[index % vertices.length][1],
        ...vertices[index % vertices.length],
      ],
    ];
  }

  String _coordinate(double start, double end) {
    if (start == end) return _number(start);
    final delta = end - start;
    final product = delta.abs() == 1 ? 't' : '${_number(delta.abs())} * t';
    if (start == 0) return delta < 0 ? '-$product' : product;
    return '${_number(start)} ${delta < 0 ? '-' : '+'} $product';
  }

  String _number(double number) {
    if (number == number.roundToDouble() && number.abs() < 1e10) return number.toInt().toString();
    return number.toString();
  }
}
