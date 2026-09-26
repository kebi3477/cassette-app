import 'package:tapeletter_app/ui/core/themes/colors.dart';
import 'package:tapeletter_app/ui/core/ui/notice_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/app.dart';
import '../../testing/fonts.dart';
import '../../testing/record_harness.dart';

/// 결제·환불 안내 문구 (전자상거래법) — 보조 글자 12px/1.6 `#9A9A97`, 레드는 쓰지 않는다.
void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpAt(WidgetTester tester, String loc) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: loc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return h;
  }

  void expectNotice(WidgetTester tester, String text) {
    final w = tester.widget<Text>(find.text(text));
    expect(w.style?.fontSize, 12);
    expect(w.style?.height, 1.6);
    expect(w.style?.color, AppColors.textMuted);
  }

  testWidgets('구매 확인 시트: 버튼 아래 구매 취소 안내', (tester) async {
    await pumpAt(tester, '/shop');
    await tester.tap(find.text('3분 테이프'));
    await tester.pumpAndSettle();
    expect(find.text(NoticeCopy.noRefundPurchase), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(NoticeCopy.noRefundPurchase)).dy,
      greaterThan(tester.getBottomLeft(find.text('구매')).dy),
    );
    expectNotice(tester, NoticeCopy.noRefundPurchase);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상점 결제 팩 아래와 충전 시트: 7일 환불 안내', (tester) async {
    final h = await pumpAt(tester, '/shop');
    await tester.scrollUntilVisible(find.text('서랍 넓히기'), 200);
    expect(find.text(NoticeCopy.refundWithin7Days), findsOneWidget);
    expectNotice(tester, NoticeCopy.refundWithin7Days);
    expect(tester.takeException(), isNull);

    h.store.credits = 10;
    h.wallet.invalidate();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('5분 테이프'), -200);
    await tester.tap(find.text('5분 테이프'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();
    expect(find.textContaining('부족해요'), findsOneWidget);
    expect(find.text(NoticeCopy.refundWithin7Days), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('회원 탈퇴 시트: 요약 상자 아래 환불 안내', (tester) async {
    await pumpAt(tester, '/my');
    await tester.scrollUntilVisible(find.text('회원 탈퇴'), 400);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    expect(find.text(NoticeCopy.refundBeforeWithdraw), findsOneWidget);
    expectNotice(tester, NoticeCopy.refundBeforeWithdraw);
    expect(
      tester.getTopLeft(find.text(NoticeCopy.refundBeforeWithdraw)).dy,
      lessThan(tester.getTopLeft(find.text('모두 사라진다는 걸 확인했어요')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
