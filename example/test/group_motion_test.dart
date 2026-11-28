import 'dart:ui' as ui;

import 'package:dotdart_example/gen/lotties.g.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (progress, expected) in [
    (0.0, [0, 255, 255, 0]),
    (15 / 31, [255, 0, 0, 255]),
    (1.0, [255, 255, 0, 0]),
  ]) {
    testWidgets('when a shared contour rotates to $progress, it should preserve its transparent overlap', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: $Lotties.rotatingCutout(width: 64, progress: progress),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final samples = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        image.dispose();
        return [
          for (final (x, y) in [(37, 32), (32, 37), (44, 32), (32, 44)]) bytes.getUint8((y * 64 + x) * 4 + 3),
        ];
      });
      expect(samples, expected);
    });
  }

  for (final (progress, expected) in [
    (0.0, [255, 0, 0, 255, 0]),
    (10 / 31, [0, 0, 255, 0, 0]),
    (1.0, [0, 255, 0, 0, 255]),
  ]) {
    testWidgets('when group motion renders at $progress, it should paint the transformed rectangle bounds', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: $Lotties.groupMotion(width: 64, progress: progress),
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
      int alpha(int x, int y) => bytes.getUint8((y * 64 + x) * 4 + 3);
      expect(
        [
          alpha(44, 32),
          alpha(32, 38),
          alpha(35, 38),
          alpha(53, 32),
          alpha(32, 43),
          alpha(4, 4),
          alpha(10, 4),
          alpha(16, 4),
        ],
        [...expected, 255, 170, 85],
      );
    });
  }
}
