import 'dart:async';

import 'package:cassette_app/data/repositories/auth_repository.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/data/services/social_auth_service.dart';
import 'package:cassette_app/routing/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/app.dart';
import '../../../testing/fonts.dart';
import '../../../testing/record_harness.dart';

/// 카카오톡을 다녀와 앱이 다시 앞으로 왔을 때의 생명 주기
void comeBack(WidgetTester tester) {
  final b = tester.binding;
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    b.handleAppLifecycleStateChanged(s);
  }
}

void main() {
  setUpAll(loadAppFonts);

  Future<RecordHarness> pumpLogin(WidgetTester tester) async {
    useDesignScreen(tester);
    final h = RecordHarness(
      store: LocalStore(newUser: true),
      signedIn: false,
      permissionsAsked: false,
    );
    await tester.pumpWidget(testApp(h, initialLocation: Routes.login));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return h;
  }

  testWidgets('카카오톡에서 돌아왔는데 SDK가 끝나지 않으면 3초 뒤 "연결 중"을 풀어 준다', (tester) async {
    final h = await pumpLogin(tester);
    h.social.kakaoPending = Completer<SocialLogin>();
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('연결 중…'), findsOneWidget);

    comeBack(tester);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.text('연결 중…'), findsOneWidget, reason: '3초는 기다린다');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('연결 중…'), findsNothing);
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(h.auth.status, AuthStatus.signedOut);

    // 다시 누르면 로그인된다
    h.social.kakaoPending = null;
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pump(const Duration(milliseconds: 800));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(h.auth.status, AuthStatus.needsName);
  });

  testWidgets('돌아온 뒤 3초 안에 끝나면 그대로 로그인', (tester) async {
    final h = await pumpLogin(tester);
    final pending = Completer<SocialLogin>();
    h.social.kakaoPending = pending;
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pump(const Duration(milliseconds: 800));
    comeBack(tester);
    await tester.pump(const Duration(seconds: 1));
    pending.complete(const KakaoLogin('late-token'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(h.auth.status, AuthStatus.needsName);
    await tester.pump(const Duration(seconds: 3));
  });
}
