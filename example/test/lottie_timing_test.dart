import 'package:dotdart_example/gen/lotties.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final preference in [
    (name: 'Reduce Motion alone', reduceMotion: true, disableAnimations: false),
    (name: 'disabled animations alone', reduceMotion: false, disableAnimations: true),
    (name: 'both preferences', reduceMotion: true, disableAnimations: true),
    (name: 'neither preference', reduceMotion: false, disableAnimations: false),
  ]) {
    testWidgets('when ${preference.name} is enabled, it should choose automatic playback accordingly', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              reduceMotion: preference.reduceMotion,
              disableAnimations: preference.disableAnimations,
            ),
            child: $Lotties.pulse(width: 96, playback: LottiePlayback.loop),
          ),
        ),
      );

      expect(tester.hasRunningAnimations, !(preference.reduceMotion || preference.disableAnimations));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('when Reduce Motion changes, it should stop and resume the existing animation', (tester) async {
    final media = ValueNotifier(const MediaQueryData());
    addTearDown(media.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder(
          valueListenable: media,
          child: $Lotties.pulse(width: 96, playback: LottiePlayback.loop),
          builder: (context, data, child) => MediaQuery(data: data, child: child!),
        ),
      ),
    );
    final playback = [tester.hasRunningAnimations];
    media.value = const MediaQueryData(reduceMotion: true);
    await tester.pump();
    playback.add(tester.hasRunningAnimations);
    media.value = const MediaQueryData();
    await tester.pump();
    playback.add(tester.hasRunningAnimations);

    expect(playback, [true, false, true]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('when motion preferences are explicitly ignored, it should continue automatic playback', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(reduceMotion: true, disableAnimations: true),
          child: $Lotties.pulse(width: 96, playback: LottiePlayback.loop, respectDisableAnimations: false),
        ),
      ),
    );

    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('when a generated Lottie has an initial delay, it should wait before autoplay starts', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: $Lotties.pulse(
          width: 96,
          delay: const Duration(milliseconds: 100),
        ),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('when a generated Lottie initial delay expires, it should start autoplay', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: $Lotties.pulse(
          width: 96,
          delay: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('when a generated Lottie uses the default playback, it should stop after one play', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: $Lotties.pulse(
          width: 96,
          duration: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('when a generated Lottie uses loop playback, it should keep playing', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: $Lotties.pulse(
          width: 96,
          duration: const Duration(milliseconds: 100),
          playback: LottiePlayback.loop,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
