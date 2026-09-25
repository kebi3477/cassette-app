import 'package:cassette_app/data/services/local/local_behavior.dart';
import 'package:cassette_app/ui/player/widgets/player_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/app.dart';
import '../../../testing/fonts.dart';
import '../../../testing/record_harness.dart';

/// 가짜 서버의 0초 지연·탭 이동·오버레이 진입을 흘려보낸다.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pump(
    WidgetTester tester, {
    FailMode mode = FailMode.none,
  }) async {
    useDesignScreen(tester);
    final h = RecordHarness(
      behavior: LocalBehavior.instant.copyWith(failMode: mode),
    );
    await tester.pumpWidget(testApp(h));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return h;
  }

  Future<void> open(WidgetTester tester, RecordHarness h, String link) async {
    h.deepLinks.open(Uri.parse(link));
    await settle(tester);
  }

  testWidgets('링크로 받기: 서랍 + 소포 화면, "친구가 되었어요" 칩', (tester) async {
    final h = await pump(tester);
    await open(tester, h, 'https://cassette.example/t/abc');
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('유진님과 친구가 되었어요'), findsOneWidget);
    expect(find.text('탭해서 뜯기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cassette://t/{token} 도 소포 화면으로', (tester) async {
    final h = await pump(tester);
    await open(tester, h, 'cassette://t/abc');
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('유진님과 친구가 되었어요'), findsOneWidget);
  });

  testWidgets('이미 다른 분이 받은 링크', (tester) async {
    final h = await pump(tester, mode: FailMode.linkTaken);
    await open(tester, h, 'cassette://t/abc');
    expect(find.text('이미 다른 분이 받은 테이프예요'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('확인'));
    await settle(tester);
    expect(find.text('이미 다른 분이 받은 테이프예요'), findsNothing);
  });

  testWidgets('만료된 링크', (tester) async {
    final h = await pump(tester, mode: FailMode.linkExpired);
    await open(tester, h, 'cassette://t/abc');
    expect(find.text('링크가 만료됐어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('내가 보낸 링크: 다시 공유하기 / 닫기', (tester) async {
    final h = await pump(tester, mode: FailMode.linkOwn);
    await open(tester, h, 'cassette://t/abc');
    expect(find.text('내가 보낸 테이프예요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('링크 다시 공유하기'));
    await settle(tester);
    expect(h.share.shared.single, contains('/t/'));
    expect(h.share.shared.single, startsWith('민경님이 테이프를 보냈어요'));
    expect(find.text('내가 보낸 테이프예요'), findsNothing);
  });

  testWidgets('로그인 전 링크는 로그인 뒤에 열린다', (tester) async {
    useDesignScreen(tester);
    final h = RecordHarness(signedIn: false);
    await tester.pumpWidget(testApp(h));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    await open(tester, h, 'cassette://t/abc');
    expect(find.byType(PlayerScreen), findsNothing);

    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pump(const Duration(milliseconds: 700));
    await settle(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('유진님과 친구가 되었어요'), findsOneWidget);
  });
}
