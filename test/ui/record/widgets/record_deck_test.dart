import 'package:flutter_test/flutter_test.dart';
import 'package:tapeletter_app/ui/record/view_model/record_view_model.dart';
import 'package:tapeletter_app/ui/record/widgets/record_deck.dart';

import '../../../../testing/app.dart';
import '../../../../testing/fonts.dart';
import '../../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpApp(WidgetTester tester) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return h;
  }

  Finder key(String label) => find.bySemanticsLabel(label);

  /// 키가 가로 가운데(195) 있는지
  void expectCentered(WidgetTester tester, String label) {
    expect(tester.getCenter(key(label)).dx, closeTo(195, 1));
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(key(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('대기: REC가 가운데, 키 6개, REC만 누를 수 있다', (tester) async {
    final h = await pumpApp(tester);
    for (final k in DeckKey.values) {
      expect(key(k.label), findsOneWidget);
    }
    expectCentered(tester, 'REC');
    // 비활성 키는 눌러도 아무 일 없다
    await press(tester, 'PLAY');
    expect(h.vm.phase, RecordPhase.idle);
    expect(tester.takeException(), isNull);

    // 눌렀다 떼면 녹음 시작 + STOP이 가운데
    await press(tester, 'REC');
    expect(h.vm.phase, RecordPhase.rec);
    expectCentered(tester, 'STOP');
    await tester.pump(const Duration(seconds: 2));
    await press(tester, 'STOP');
    expect(h.vm.phase, RecordPhase.confirm);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('누른 채 키 밖으로 나가면 취소', (tester) async {
    final h = await pumpApp(tester);
    final g = await tester.startGesture(tester.getCenter(key('REC')));
    await tester.pump();
    await g.moveBy(const Offset(0, -120));
    await g.up();
    await tester.pump();
    expect(h.vm.phase, RecordPhase.idle);
  });

  testWidgets('확인: PLAY가 가운데, 동그란 재생 버튼 없음, FF·REW·STOP', (tester) async {
    final h = await pumpApp(tester);
    await press(tester, 'REC');
    await tester.pump(const Duration(seconds: 3));
    await press(tester, 'STOP');
    await tester.pump(const Duration(seconds: 2));
    expect(h.vm.previewReady, isTrue);
    expectCentered(tester, 'PLAY');
    expect(find.text('누구에게 보낼까요?'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('누구에게 보낼까요?')).dy,
      lessThan(tester.getTopLeft(key('PLAY')).dy),
      reason: '"누구에게 보낼까요?"는 데크 위',
    );
    expect(tester.takeException(), isNull);

    // 미리 듣기가 자동으로 재생 중 → STOP으로 멈춤
    expect(h.vm.playing, isTrue);
    await press(tester, 'STOP');
    expect(h.vm.playing, isFalse);
    await press(tester, 'REW');
    expect(h.vm.pos, 0);
    // FF는 PLAY가 가운데일 때 390 화면 오른쪽 밖(원본과 같다) → ViewModel로 확인
    expect(tester.getCenter(key('FF')).dx, greaterThan(390));
    await h.vm.fastForward();
    await tester.pump();
    expect(h.vm.pos, h.vm.recorded < 5 ? h.vm.recorded : 5);
    expect(h.vm.pos, greaterThan(0));
    await press(tester, 'REW');
    expect(h.vm.pos, 0);
    await press(tester, 'PLAY');
    expect(h.vm.playing, isTrue);
    await press(tester, 'PLAY');
    expect(h.vm.playing, isFalse);
  });

  testWidgets('확인에서 REC → 다시 녹음할까요? → 지우고 다시 녹음 → 대기(자동 녹음 안 함)', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await press(tester, 'REC');
    await tester.pump(const Duration(seconds: 3));
    await press(tester, 'STOP');
    await tester.pump(const Duration(seconds: 2));
    await press(tester, 'REC');
    expect(find.text('다시 녹음할까요?'), findsOneWidget);
    expect(h.vm.playing, isFalse);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('다시 녹음할까요?'), findsNothing);
    expect(h.vm.phase, RecordPhase.confirm);

    await press(tester, 'REC');
    await tester.tap(find.text('지우고 다시 녹음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(h.vm.phase, RecordPhase.idle);
    expect(find.text('다시 녹음할까요?'), findsNothing);
    expect(h.recorder.calls.where((c) => c == 'start'), hasLength(1));
    expectCentered(tester, 'REC');
  });
}
