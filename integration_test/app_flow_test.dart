import 'package:cassette_app/config/env.dart';
import 'package:cassette_app/data/services/app_prefs.dart';
import 'package:cassette_app/data/services/api/http_api_client.dart';
import 'package:cassette_app/main.dart' as app;
import 'package:cassette_app/ui/core/ui/brand.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 시뮬레이터에서 앱을 띄워 개발 로그인 → 녹음 → 서랍 → 재생 → 상점 → 마이를 지나며 화면을 찍는다.
///
/// ```bash
/// tool/sim_flow.sh <시뮬레이터 UDID> http://localhost:3000/api   # build/screenshots/server_*.png
/// tool/sim_flow.sh <시뮬레이터 UDID>                             # 가짜 서버: local_*.png
/// ```
/// `API_BASE_URL`이 없으면 가짜 서버로 같은 흐름을 찍는다 (둘을 비교).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final server = Env.apiBaseUrl.isNotEmpty;
  final tag = server ? 'server' : 'local';

  // iOS에서는 takeScreenshot이 빈 화면을 줄 때가 있어, 로그에 표시를 남기고
  // 바깥에서 `xcrun simctl io <기기> screenshot`으로 찍는다 (docs/SETUP.md).
  Future<void> shot(String name) async {
    // ignore: avoid_print
    print('CASSETTE_SHOT ${tag}_$name');
    final end = DateTime.now().add(const Duration(milliseconds: 1500));
    while (DateTime.now().isBefore(end)) {
      await binding.delayed(const Duration(milliseconds: 100));
    }
  }

  testWidgets('개발 로그인부터 마이까지', (tester) async {
    if (server) {
      // 앱의 개발 로그인 계정(minkyung)을 프로토타입 데이터로
      final api = HttpApiClient(baseUrl: Env.apiBaseUrl);
      final auth = await api.authDev(key: 'minkyung', name: '민경');
      api.accessToken = auth.tokens.accessToken;
      await api.devSeed();
    }

    // 마이크·알림 안내는 OS 권한 창이 화면을 가리므로 건너뛴다 (위젯 시험에서 확인).
    // 시뮬레이터는 simctl privacy로 마이크를 미리 허용해도 flutter drive가 다시 설치하며 초기화한다.
    await SharedAppPrefs().setPermissionsAsked();

    await app.main();

    Future<void> wait(Duration d) async {
      final end = DateTime.now().add(d);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<bool> waitFor(Finder f, {int seconds = 10}) async {
      for (var i = 0; i < seconds * 10; i++) {
        if (f.evaluate().isNotEmpty) return true;
        await tester.pump(const Duration(milliseconds: 100));
      }
      return false;
    }

    // 스플래시 → 온보딩(처음 설치일 때) → 로그인
    await wait(const Duration(seconds: 2));
    if (await waitFor(find.text('건너뛰기'), seconds: 2)) {
      await shot('onboarding');
      await tester.tap(find.text('건너뛰기'));
      await wait(const Duration(seconds: 1));
    }
    if (await waitFor(find.text('카카오로 시작하기'), seconds: 3)) {
      await shot('login');
      // 개발 빌드의 숨은 진입점: 앱 아이콘 길게 누르기 → POST /auth/dev
      await tester.longPress(find.byType(AppIconMark));
      await wait(const Duration(seconds: 2));
    }

    // 녹음 탭
    expect(await waitFor(find.text('녹음')), isTrue);
    await wait(const Duration(seconds: 2));
    await shot('record');

    // 서랍
    await tester.tap(find.text('서랍').last);
    await wait(const Duration(seconds: 2));
    await shot('shelf');

    // 칸의 테이프 재생 (GET /deliveries/{id}/audio → 캐시 파일)
    await tester.tap(find.text('수아').first);
    await wait(const Duration(seconds: 3));
    await shot('player');
    await tester.tap(find.text('✕'));
    await wait(const Duration(seconds: 1));

    // 안 뜯은 소포 → 뜯기 → 재생
    await tester.tap(find.text('지현').first);
    await wait(const Duration(seconds: 2));
    await shot('parcel');
    await tester.tap(find.text('탭해서 뜯기'));
    await wait(const Duration(seconds: 3));
    await shot('unwrapped');
    await tester.tap(find.text('✕'));
    await wait(const Duration(seconds: 1));

    // 상점 · 마이
    await tester.tap(find.text('상점').last);
    await wait(const Duration(seconds: 2));
    await shot('shop');
    await tester.tap(find.text('마이').last);
    await wait(const Duration(seconds: 2));
    await shot('my');
    expect(find.text('민경'), findsWidgets);
  });
}
