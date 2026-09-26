import 'package:tapeletter_app/ui/core/ui/tab_bar.dart';
import 'package:tapeletter_app/ui/shelf/widgets/shelf_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/app.dart';
import '../../../../testing/fonts.dart';
import '../../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpShelf(WidgetTester tester) async {
    useDesignScreen(tester);
    // 목록 보기를 골라 둔 사용자 (행을 눌러 연다)
    final h = RecordHarness()..prefs.shelfViewValue = 'list';
    await tester.pumpWidget(testApp(h, initialLocation: '/shelf'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return h;
  }

  Finder rowOf(String text) =>
      find.ancestor(of: find.text(text), matching: find.byType(ShelfRow));

  testWidgets('소포: 링크 칩 → 탭해서 뜯기 → 재생 → 닫기, 레드 점 줄어듦', (tester) async {
    final h = await pumpShelf(tester);
    await tester.tap(rowOf('하늘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('하늘님과 친구가 되었어요'), findsOneWidget);
    expect(find.text('탭해서 뜯기'), findsOneWidget);
    expect(find.text('보낸 사람'), findsOneWidget);

    await tester.tap(find.text('탭해서 뜯기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('테이프를 불러오는 중이에요'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('분류 안 함'), findsWidgets);
    expect(find.text('순서대로 재생'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('재생 중'), findsOneWidget);
    expect(find.text('09.23'), findsOneWidget); // 테이프 제목(날짜)
    expect(h.player.playing, isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.player.calls.last, 'stop');
    expect(h.store.unsorted.last.opened, isTrue);
    final tab = tester.widget<AppTabBar>(find.byType(AppTabBar));
    expect(tab.hasNew, isTrue, reason: '지현 소포가 아직 남아 있다');
  });

  testWidgets('칸 재생: 이어 듣기 목록, 반복, 다음 곡', (tester) async {
    final h = await pumpShelf(tester);
    await tester.tap(rowOf('수아'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('2026 생일'), findsWidgets);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('0:48'), findsOneWidget); // 엄마 3분 = 48s
    await tester.tap(find.bySemanticsLabel('반복'));
    await tester.pump();
    expect(find.text('전체 반복'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('다음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('4/4'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('다음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('1/4'), findsOneWidget);
    expect(h.player.loaded, 'asset:///assets/audio/sample_48s.m4a');
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('재생 불러오기 실패 → 다시 시도', (tester) async {
    final h = await pumpShelf(tester);
    h.player.failLoad = true;
    await tester.tap(rowOf('수아'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('테이프를 불러오지 못했어요'), findsOneWidget);
    h.player.failLoad = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('테이프를 불러오지 못했어요'), findsNothing);
    expect(h.player.playing, isTrue);
  });
}
