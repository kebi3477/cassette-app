import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapeletter_app/data/services/sound_service.dart';
import 'package:tapeletter_app/ui/core/ui/ui_sound.dart';
import 'package:tapeletter_app/ui/record/view_model/record_view_model.dart';

import '../../../../testing/app.dart';
import '../../../../testing/fakes/services/fake_sound_service.dart';
import '../../../../testing/fonts.dart';
import '../../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    '데크 REC(390×844): 떼면 on.wav, STOP이 0.45초에 가운데, 녹음은 on.wav가 끝난 0.54초에',
    (tester) async {
      useDesignScreen(tester);
      final h = RecordHarness();
      h.sound.realDuration = true;
      await tester.pumpWidget(testApp(h));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      h.recorder.calls.clear();

      await tester.tap(find.bySemanticsLabel('REC'));
      await tester.pump();
      expect(h.recorder.calls, ['sound:on']);
      expect(h.vm.arming, isTrue);
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        tester.getCenter(find.bySemanticsLabel('STOP')).dx,
        closeTo(195, 1),
        reason: '데크는 소리가 끝나기 전에 STOP을 가운데로 민다',
      );
      expect(h.recorder.calls, isNot(contains('start')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(h.recorder.calls, ['sound:on', 'sound:on:end', 'start']);
      expect(h.vm.phase, RecordPhase.rec);

      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.bySemanticsLabel('STOP'));
      await tester.pump();
      expect(h.recorder.calls.sublist(3, 5), ['stop', 'sound:off']);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('‹ 뒤로 · ✕ 닫기는 off.wav', (tester) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: '/my'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.bySemanticsLabel('받은 테이프'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.sound.played, isEmpty);
    await tester.tap(find.text('‹'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.sound.played, [UiSound.off]);

    // 재생 화면 ✕
    await tester.tap(find.bySemanticsLabel('받은 테이프'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.textContaining('2026 생일 ·').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.sound.played, [UiSound.off, UiSound.off]);
    await tester.pump(const Duration(seconds: 2));
  });

  group('BackSoundObserver', () {
    late FakeSoundService sound;
    setUp(() => UiSounds.service = sound = FakeSoundService());
    tearDown(() => UiSounds.service = const NoSoundService());

    test('Android 뒤로 버튼: 소리만 내고 처리는 넘긴다(false)', () async {
      final o = BackSoundObserver();
      expect(await o.didPopRoute(), isFalse);
      expect(sound.played, [UiSound.off]);
    });

    testWidgets('iOS 밀어서 뒤로: 제스처로 pop될 때만 울린다', (tester) async {
      final o = BackSoundObserver();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [o],
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Text('첫 화면'),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      // 코드로 pop → 조용
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(sound.played, isEmpty);

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      // 왼쪽 가장자리에서 오른쪽으로 밀기
      final g = await tester.startGesture(const Offset(5, 300));
      await g.moveBy(const Offset(400, 0));
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('첫 화면'), findsOneWidget);
      expect(sound.played, [UiSound.off]);
    });
  });
}
