import 'package:cassette_app/ui/shop/view_model/shop_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/app.dart';
import '../../../../testing/fonts.dart';
import '../../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpShop(
    WidgetTester tester, {
    String loc = '/shop',
  }) async {
    useDesignScreen(tester);
    final h = RecordHarness();
    await tester.pumpWidget(testApp(h, initialLocation: loc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return h;
  }

  testWidgets('상점: 헤더 잔액, 테이프 4종, 크레딧 받기, 팩, 서랍', (tester) async {
    await pumpShop(tester);
    expect(find.text('120'), findsNWidgets(2)); // 잔액 + 3분 5개 가격
    for (final t in ['3분 테이프', '3분 테이프 5개', '5분 테이프', '5분 테이프 5개']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('보유 2개'), findsNWidgets(2));
    expect(find.text('크레딧 선물하기'), findsOneWidget);
    expect(find.text('오늘 3번 남음'), findsOneWidget);
    expect(find.text('1,200'), findsOneWidget);
    expect(find.text('₩11,000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('서랍 넓히기'), 200);
    expect(find.text('테이프 10개 더 보관 · 지금 10/12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('구매 시트 → 구매 → 토스트, 보유 증가', (tester) async {
    final h = await pumpShop(tester);
    await tester.tap(find.text('3분 테이프'));
    await tester.pumpAndSettle();
    expect(find.text('30 크레딧 · 남는 크레딧 90'), findsOneWidget);
    await tester.tap(find.text('구매'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('보유 테이프에 넣었어요'), findsOneWidget);
    expect(find.text('보유 3개'), findsNWidgets(2));
    expect(h.shopVm.credits, 90);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('부족 → 충전 시트 → 팩 → 결제 중 → 원래 구매 시트', (tester) async {
    final h = await pumpShop(tester);
    h.iap.delay = const Duration(milliseconds: 1400);
    await tester.tap(find.text('5분 테이프 5개'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('구매'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('크레딧이 80 부족해요'), findsOneWidget);
    expect(find.text('+10 · 3번 남음'), findsOneWidget);
    await tester.tap(find.text('100 크레딧'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('₩1,100 결제 중이에요'), findsOneWidget);
    expect(find.text('100 크레딧 · 잠시만 기다려 주세요'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('5분 테이프 5개'), findsWidgets);
    expect(find.text('200 크레딧 · 남는 크레딧 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('광고 시트 카운트와 ✕', (tester) async {
    final h = await pumpShop(tester);
    await tester.tap(find.text('광고 보고 받기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('광고'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('끝까지 보면 10 크레딧을 받아요'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('광고 닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('끝까지 봐야 받을 수 있어요'), findsOneWidget);
    expect(h.shopVm.sheet, isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('선물 시트: 받는 사람 칩, 금액, 보내기', (tester) async {
    final h = await pumpShop(tester);
    await tester.tap(find.text('크레딧 선물하기'));
    await tester.pumpAndSettle();
    expect(find.text('받는 사람을 골라주세요'), findsOneWidget);
    expect(find.text('보유 120'), findsOneWidget);
    await tester.tap(find.text('엄마'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('50 크레딧'));
    await tester.pump();
    expect(find.text('엄마에게 50 크레딧 보내기'), findsOneWidget);
    await tester.tap(find.text('엄마에게 50 크레딧 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('엄마님에게 50 크레딧을 선물했어요'), findsOneWidget);
    expect(h.shopVm.sheet, isNull);
    expect(h.shopVm.credits, 70);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('딤을 눌러 닫으면 시트 상태도 비운다', (tester) async {
    final h = await pumpShop(tester);
    await tester.tap(find.text('3분 테이프'));
    await tester.pumpAndSettle();
    expect(h.shopVm.sheet, isA<BuySheet>());
    await tester.tapAt(const Offset(195, 100));
    await tester.pumpAndSettle();
    expect(h.shopVm.sheet, isNull);
  });

  testWidgets('녹음 탭에서 온 /shop?hl=5', (tester) async {
    final h = await pumpShop(tester, loc: '/shop?hl=5');
    expect(h.shopVm.highlight?.minutes, 5);
    await tester.pump(const Duration(seconds: 2));
  });
}
