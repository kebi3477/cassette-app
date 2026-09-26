import 'package:tapeletter_app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/app.dart';
import '../../../../testing/fonts.dart';
import '../../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpMy(WidgetTester tester) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: '/my'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return h;
  }

  testWidgets('마이: 이름, 크레딧, 통계, 보유, 친구, 보낸 테이프, 설정', (tester) async {
    await pumpMy(tester);
    expect(find.text('민경'), findsOneWidget);
    expect(find.text('테이프에 적히는 이름이에요'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('받은 테이프'), findsOneWidget);
    expect(find.text('1분 무료', findRichText: true), findsOneWidget);
    expect(find.text('5분 0개', findRichText: true), findsOneWidget);
    await tester.scrollUntilVisible(find.text('유진에게 보냄'), 300);
    expect(find.text('09.22 · 링크 대기'), findsOneWidget);
    expect(find.text('09.10 · 09.11 들음'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('회원 탈퇴'), 300);
    expect(find.text('카카오'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('크레딧 행 → 크레딧 내역 → 충전하기 → 상점', (tester) async {
    await pumpMy(tester);
    await tester.tap(find.text('크레딧'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('충전하기'), findsOneWidget);
    expect(find.text('광고 보상'), findsOneWidget);
    expect(find.text('+10'), findsWidgets);
    expect(find.text('−30'), findsOneWidget);
    await tester.tap(find.text('충전하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('크레딧 받기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('이름 수정', (tester) async {
    final h = await pumpMy(tester);
    await tester.tap(find.text('수정'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '민경이');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
    expect(h.store.name, '민경이');
    expect(find.text('민경이'), findsOneWidget);
  });

  testWidgets('친구 ⋯ → 차단 확인 → 차단한 친구 시트에서 해제', (tester) async {
    final h = await pumpMy(tester);
    await tester.scrollUntilVisible(find.text('민수'), 200);
    await tester.tap(find.bySemanticsLabel('민수 더 보기'));
    await tester.pumpAndSettle();
    expect(find.text('녹음해서 보내기'), findsOneWidget);
    expect(find.text('친구 삭제'), findsOneWidget);
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();
    expect(find.text('민수님을 차단할까요?'), findsOneWidget);
    await tester.tap(find.text('차단하기'));
    await tester.pumpAndSettle();
    expect(find.text('민수님을 차단했어요'), findsOneWidget);
    expect(h.myVm.blockedCountText, '1명');

    await tester.scrollUntilVisible(find.text('차단한 친구'), 300);
    await tester.tap(find.text('차단한 친구'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('해제'));
    await tester.pumpAndSettle();
    expect(find.text('차단한 친구가 없어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('친구 ⋯ → 크레딧 선물하기는 그 친구를 골라 둔다', (tester) async {
    await pumpMy(tester);
    await tester.scrollUntilVisible(find.text('하늘'), 200);
    await tester.tap(find.bySemanticsLabel('하늘 더 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('크레딧 선물하기'));
    await tester.pumpAndSettle();
    expect(find.text('하늘에게 30 크레딧 보내기'), findsOneWidget);
  });

  testWidgets('보낸 테이프 상세와 링크 다시 공유하기', (tester) async {
    final h = await pumpMy(tester);
    await tester.scrollUntilVisible(find.text('유진에게 보냄'), 300);
    await tester.tap(find.text('유진에게 보냄'));
    await tester.pumpAndSettle();
    expect(find.text('유진에게 보낸 테이프'), findsOneWidget);
    expect(find.text('아직 아무도 받지 않았어요'), findsOneWidget);
    expect(find.text('테이프는 이제 받는 사람만 들을 수 있어요'), findsOneWidget);
    await tester.tap(find.text('링크 다시 공유하기'));
    await tester.pumpAndSettle();
    expect(h.deliveries.reshares, 1);
  });

  testWidgets('회원 탈퇴: 체크해야 탈퇴, 끝나면 첫 화면', (tester) async {
    final h = await pumpMy(tester);
    await tester.scrollUntilVisible(find.text('회원 탈퇴'), 400);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
    expect(find.text('10개'), findsOneWidget);
    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
    await tester.tap(find.text('모두 사라진다는 걸 확인했어요'));
    await tester.pump();
    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();
    expect(find.text('탈퇴했어요. 그동안 고마웠어요'), findsOneWidget);
    expect(h.auth.status, AuthStatus.signedOut);
    // 로그인 화면으로
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
