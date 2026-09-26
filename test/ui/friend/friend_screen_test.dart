import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/app.dart';
import '../../../testing/fonts.dart';
import '../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('친구 화면: 제목·부제·목록, 모두 재생, 녹음해서 보내기', (tester) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: '/friends/u-mom'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('엄마'), findsOneWidget);
    expect(find.text('받은 테이프 3개'), findsOneWidget);
    expect(find.text('3분 · 2026 생일'), findsOneWidget);
    expect(find.text('1분 · 엄마 목소리'), findsOneWidget);
    expect(find.text('모두 재생'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('모두 재생'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('엄마님의 테이프'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('녹음해서 보내기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.vm.to?.name, '엄마');
    expect(find.text('엄마에게'), findsOneWidget);
  });

  testWidgets('뜯은 테이프가 없는 친구', (tester) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: '/friends/u-jihyun'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('뜯지 않은 테이프 1개'), findsOneWidget);
    expect(find.text('아직 받은 테이프가 없어요'), findsOneWidget);
  });

  testWidgets('별명 설정: 시트(390×844) → 제목은 별명, 부제에 원래 이름 → 비우면 원래대로', (
    tester,
  ) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: '/friends/u-mom'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('별명 설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('엄마님의 별명'), findsOneWidget);
    expect(find.text('나에게만 보여요. 엄마님에게는 보이지 않아요'), findsOneWidget);
    expect(find.text('비우면 원래 이름으로 보여요'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '우리 엄마 목소리가 좋아');
    await tester.pump();
    expect(find.text('10/10'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '우리 엄마');
    await tester.pump();
    expect(find.text('5/10'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('우리 엄마'), findsOneWidget);
    expect(find.text('엄마 · 받은 테이프 3개'), findsOneWidget);
    expect(find.text('별명을 저장했어요'), findsOneWidget);

    // Enter로 저장 — 비우면 원래 이름
    await tester.tap(find.text('별명 설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('5/10'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('받은 테이프 3개'), findsOneWidget);
    expect(find.text('원래 이름으로 보여요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
