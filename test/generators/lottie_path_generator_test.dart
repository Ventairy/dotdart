import 'dart:io';

import 'package:dotdart/src/generators/lottie_path_generator.dart';
import 'package:dotdart/src/models/lottie_shape.dart';
import 'package:dotdart/src/parsers/lottie_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when emitting an animated path, it should specialize coordinates and reuse instance storage', () {
    final path = LottieParser.parse(
      File('test/fixtures/generated_consumer/assets/lotties/path_morph.json').readAsStringSync(),
    ).animation.layers.single.shapeGroups.single.items.whereType<LottiePath>().single;
    final output = StringBuffer();
    const LottiePathGenerator().write(output, name: '_outline', path: path, easing: (_) => 'progress');
    expect(
      output.toString(),
      allOf([
        contains('final Path _outlineValue = Path();'),
        contains('if (frame == _outlineFrame) return _outlineValue;'),
        contains('_outlineSegment == 0 && _outlineT == t'),
        contains('..moveTo(10 + 40 * t, 10)'),
        contains('..reset()'),
        isNot(contains('List<')),
        isNot(contains('Offset(')),
        isNot(contains('static final Path')),
      ]),
    );
  });
}
