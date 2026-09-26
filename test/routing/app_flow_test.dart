import 'package:tapeletter_app/data/repositories/auth_repository.dart';
import 'package:tapeletter_app/data/services/local/local_behavior.dart';
import 'package:tapeletter_app/data/services/local/local_store.dart';
import 'package:tapeletter_app/routing/app_flow.dart';
import 'package:tapeletter_app/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/record_harness.dart';

void main() {
  String? decide({
    bool ready = true,
    bool update = false,
    bool onboarded = true,
    AuthStatus auth = AuthStatus.signedIn,
    bool permissions = true,
    String location = Routes.record,
  }) => AppFlow.decide(
    ready: ready,
    updateRequired: update,
    onboarded: onboarded,
    auth: auth,
    permissionsAsked: permissions,
    location: location,
  );

  group('관문 규칙', () {
    test('준비 전에는 스플래시', () {
      expect(decide(ready: false), Routes.splash);
      expect(decide(ready: false, location: Routes.splash), isNull);
    });

    test('강제 업데이트가 가장 먼저', () {
      expect(decide(update: true, auth: AuthStatus.signedOut), Routes.update);
      expect(decide(update: true, location: Routes.update), isNull);
    });

    test('처음 실행이면 온보딩', () {
      expect(
        decide(onboarded: false, auth: AuthStatus.signedOut),
        Routes.onboarding,
      );
    });

    test('로그아웃 상태면 로그인', () {
      expect(decide(auth: AuthStatus.signedOut), Routes.login);
      expect(decide(auth: AuthStatus.signedOut, location: '/my'), Routes.login);
      expect(
        decide(auth: AuthStatus.signedOut, location: Routes.login),
        isNull,
      );
    });

    test('이름이 없으면 이름 정하기', () {
      expect(decide(auth: AuthStatus.needsName), Routes.name);
      expect(
        decide(auth: AuthStatus.needsName, location: Routes.login),
        Routes.name,
      );
    });

    test('로그인했는데 권한 안내 전이면 마이크 안내부터', () {
      expect(decide(permissions: false), Routes.permissionsMic);
      expect(
        decide(permissions: false, location: Routes.permissionsNoti),
        isNull,
      );
    });

    test('로그인 상태: 관문 화면이면 녹음으로, 앱 안이면 그대로', () {
      expect(decide(location: Routes.login), Routes.record);
      expect(decide(location: Routes.splash), Routes.record);
      expect(decide(location: '/my'), isNull);
      expect(decide(location: Routes.linkError), isNull);
    });
  });

  group('AppFlow', () {
    test('관문을 거친 뒤 처음 가려던 곳으로 돌아간다', () async {
      final h = RecordHarness();
      final flow = h.flow;
      expect(flow.redirect('/my'), Routes.splash, reason: '아직 boot 중');
      await pumpEventQueue();
      expect(flow.ready, isTrue);
      expect(flow.redirect(Routes.splash), '/my');
      expect(flow.redirect(Routes.login), Routes.record);
    });

    test('처음 실행: 온보딩 → 로그인 → 이름 → 권한 → 녹음', () async {
      final h = RecordHarness(
        store: LocalStore(newUser: true),
        signedIn: false,
        onboarded: false,
        permissionsAsked: false,
      );
      final flow = h.flow;
      await pumpEventQueue();
      expect(flow.redirect(Routes.splash), Routes.onboarding);

      await flow.finishOnboarding();
      expect(await h.prefs.onboarded(), isTrue, reason: '기기에 저장');
      expect(flow.redirect(Routes.onboarding), Routes.login);

      await h.auth.signInKakao();
      expect(h.auth.status, AuthStatus.needsName);
      expect(h.auth.suggestedName, '민경');
      expect(flow.redirect(Routes.login), Routes.name);

      await h.auth.setName('민경');
      expect(flow.redirect(Routes.name), Routes.permissionsMic);
      expect(flow.inApp, isFalse);

      await flow.finishPermissions();
      expect(await h.prefs.permissionsAsked(), isTrue);
      expect(flow.redirect(Routes.permissionsNoti), Routes.record);
      expect(flow.inApp, isTrue);
    });

    test('로그아웃하면 로그인 화면으로', () async {
      final h = RecordHarness();
      final flow = h.flow;
      await pumpEventQueue();
      expect(flow.redirect('/my'), isNull);
      await h.auth.logout();
      expect(h.flow.redirect('/my'), Routes.login);
    });

    test('강제 업데이트: GET /app-version updateRequired', () async {
      final h = RecordHarness(
        behavior: LocalBehavior.instant.copyWith(
          failMode: FailMode.forceUpdate,
        ),
      );
      final flow = h.flow;
      await pumpEventQueue();
      expect(flow.updateRequired, isTrue);
      expect(h.flow.storeUrl, isNotNull);
      expect(h.flow.redirect('/record'), Routes.update);
    });
  });
}
