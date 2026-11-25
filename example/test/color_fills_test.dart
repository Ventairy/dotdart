import 'dart:ui' as ui;

import 'package:dotdart_example/gen/lotties.g.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (progress, solid, track) in [
    (0.0, [255, 0, 0], [0, 255, 0]),
    (10 / 21, [128, 0, 128], [128, 255, 0]),
    (1.0, [0, 0, 255], [255, 255, 0]),
  ]) {
    testWidgets('when color fills render at $progress, it should paint the solid, linear and radial colors', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: $Lotties.colorFills(width: 60, progress: progress),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;
      List<int> pixel(int x) => [for (var i = 0; i < 4; i++) bytes.getUint8((10 * 60 + x) * 4 + i)];
      expect(
        [...pixel(10), ...pixel(35), pixel(50).last, pixel(55).last],
        [
          for (final channel in [...solid, 255, ...track, 255]) closeTo(channel, 1),
          closeTo(237, 3),
          closeTo(114, 3),
        ],
      );
    });
  }
}
