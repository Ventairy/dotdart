import 'package:dotdart/src/models/lottie_keyframe.dart';
import 'package:dotdart/src/models/lottie_path_keyframe.dart';
import 'package:dotdart/src/models/lottie_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when a path keyframe is constructed, it should retain geometry and normalized timing', () {
    const pose = LottiePath(
      vertices: [
        [0, 0],
      ],
      inTangents: [
        [0, 0],
      ],
      outTangents: [
        [0, 0],
      ],
      closed: false,
    );
    const timing = LottieScalarKeyframe(time: 12, start: 0, end: 1, hold: true);
    const frame = LottiePathKeyframe(start: pose, end: pose, timing: timing);
    expect((frame.start, frame.end, frame.timing), (pose, pose, timing));
  });
}
