import 'package:cassette_app/data/model/api_error.dart';
import 'package:cassette_app/data/repositories/auth_repository.dart';
import 'package:cassette_app/data/services/local/local_behavior.dart';
import 'package:cassette_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/record_harness.dart';

void main() {
  final auth = LocalBehavior.instant.copyWith(requireAuth: true);

  test('토큰을 붙여 보내고, 401이면 refresh 후 한 번 다시 보낸다', () async {
    final h = RecordHarness(behavior: auth);
    final before = h.tokens.tokens!;
    expect((await h.users.getMe()), isA<Ok<Object?>>());

    h.api.expireAccessTokens();
    h.users.invalidate();
    final r = await h.users.getMe();
    expect(r, isA<Ok<Object?>>(), reason: 'refresh 뒤 재시도 성공');
    final after = h.tokens.tokens!;
    expect(after.access, isNot(before.access));
    expect(after.refresh, isNot(before.refresh), reason: 'refresh token 회전');
    expect(h.auth.status, isNot(AuthStatus.signedOut));
  });

  test('동시에 401이 나도 refresh는 한 번만', () async {
    final h = RecordHarness(behavior: auth);
    h.api.expireAccessTokens();
    final results = await Future.wait([
      h.client.getMe(),
      h.client.getWallet(),
      h.client.getFriends(),
    ]);
    expect(results, hasLength(3));
    expect(h.store.refreshTokens, hasLength(1), reason: '회전된 토큰 하나만 남는다');
  });

  test('refresh도 실패하면 토큰을 지우고 로그인 화면으로', () async {
    final h = RecordHarness(behavior: auth);
    await h.auth.restore();
    expect(h.auth.status, AuthStatus.signedIn);
    h.api.expireAccessTokens();
    h.store.refreshTokens.clear();

    await expectLater(
      h.client.getMe(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    await pumpEventQueue();
    expect(h.tokens.tokens, isNull);
    expect(h.auth.status, AuthStatus.signedOut);
  });

  test('서버 5xx·네트워크 오류는 상태로 알린다', () async {
    final h = RecordHarness(
      behavior: LocalBehavior.instant.copyWith(failMode: FailMode.serverError),
    );
    await expectLater(h.client.getMe(), throwsA(isA<ApiException>()));
    expect(h.apiStatus.serverError, isTrue);
  });
}
