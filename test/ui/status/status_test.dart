import 'package:tapeletter_app/data/services/local/local_behavior.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/app.dart';
import '../../../testing/fonts.dart';
import '../../../testing/record_harness.dart';

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
    await settle(tester);
    return h;
  }

  testWidgets('인터넷이 끊기면 배너, 돌아오면 사라진다', (tester) async {
    final h = await pump(tester);
    expect(find.text('인터넷에 연결되어 있지 않아요'), findsNothing);
    h.connectivity.set(false);
    await settle(tester);
    expect(find.text('인터넷에 연결되어 있지 않아요'), findsOneWidget);
    expect(tester.takeException(), isNull);
    h.connectivity.set(true);
    await settle(tester);
    expect(find.text('인터넷에 연결되어 있지 않아요'), findsNothing);
  });

  testWidgets('요청이 네트워크 오류로 실패해도 배너', (tester) async {
    final h = await pump(tester);
    h.apiStatus.reportNetworkFailure();
    await settle(tester);
    expect(find.text('인터넷에 연결되어 있지 않아요'), findsOneWidget);
    h.apiStatus.reportOk();
    await settle(tester);
    expect(find.text('인터넷에 연결되어 있지 않아요'), findsNothing);
  });

  testWidgets('서버 5xx: 오류 화면, 다시 시도해도 안 되면 토스트', (tester) async {
    await pump(tester, mode: FailMode.serverError);
    expect(find.text('잠시 문제가 생겼어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.text('다시 시도하는 중…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(find.text('아직 문제가 있어요. 잠시 후 다시 해주세요'), findsOneWidget);
    expect(find.text('잠시 문제가 생겼어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('서버가 돌아오면 다시 시도로 닫힌다', (tester) async {
    final h = await pump(tester);
    h.apiStatus.reportServerError();
    await settle(tester);
    expect(find.text('잠시 문제가 생겼어요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pump(const Duration(milliseconds: 900));
    await settle(tester);
    expect(find.text('잠시 문제가 생겼어요'), findsNothing);
  });
}
