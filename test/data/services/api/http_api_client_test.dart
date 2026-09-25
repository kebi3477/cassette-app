import 'package:cassette_app/data/model/api_error.dart';
import 'package:cassette_app/data/model/me_dto.dart';
import 'package:cassette_app/data/services/api/http_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/fakes/services/fake_http_adapter.dart';

const _me = {
  'id': 'u1',
  'name': '민경',
  'credits': 120,
  'drawer': {'stored': 10, 'cap': 12, 'full': false, 'unopenedCount': 2},
  'tapes': [
    {'tapeType': 1, 'qty': null},
    {'tapeType': 3, 'qty': 2},
    {'tapeType': 5, 'qty': 0},
  ],
  'stats': {'receivedCount': 10, 'sentCount': 4, 'friendCount': 6},
  'providers': ['dev'],
  'notificationsEnabled': true,
  'createdAt': '2026-09-01T00:00:00.000Z',
};

const _entry = {
  'id': 'l1',
  'delta': -30,
  'reason': '3분 테이프 구매',
  'kind': 'purchase',
  'createdAt': '2026-09-25T00:00:00.000Z',
};

const _purchase = {
  'credits': 90,
  'tapes': [
    {'tapeType': 1, 'qty': null},
  ],
  'drawer': {'stored': 1, 'cap': 12, 'full': false, 'unopenedCount': 0},
  'entry': _entry,
};

void main() {
  late FakeHttpAdapter adapter;
  late HttpApiClient api;

  void serve((int, Object?) Function(RequestOptions r, List<int> body) h) {
    adapter = FakeHttpAdapter(h);
    final dio = Dio()..httpClientAdapter = adapter;
    api = HttpApiClient(
      baseUrl: 'http://api.test/api/',
      dio: dio,
      inProgressRetryDelay: Duration.zero,
    );
  }

  test('기본 주소 + 경로, Bearer 토큰, JSON 본문', () async {
    serve((r, _) => (200, _me));
    api.accessToken = 'tok';
    final me = await api.patchMe(const PatchMeRequest(name: '민경'));
    expect(me.name, '민경');
    final r = adapter.requests.single;
    expect(r.method, 'PATCH');
    expect(r.uri.toString(), 'http://api.test/api/users/me');
    expect(r.headers['Authorization'], 'Bearer tok');
    expect(adapter.lastJson, {'name': '민경'});
  });

  test('공개 API에는 토큰을 붙이지 않는다', () async {
    serve((r, _) => (200, {'status': 'ok'}));
    api.accessToken = 'tok';
    await api.health();
    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('커서 페이지: 없는 값은 쿼리에서 뺀다', () async {
    serve((r, _) => (200, {'items': [], 'nextCursor': null}));
    await api.getLedger();
    expect(adapter.requests.last.uri.query, '');
    await api.getLedger(cursor: 'abc', limit: 30);
    expect(adapter.requests.last.uri.queryParameters, {
      'cursor': 'abc',
      'limit': '30',
    });
  });

  test('🔑 요청은 Idempotency-Key 헤더', () async {
    serve(
      (r, _) => (
        201,
        {
          'credits': 90,
          'tapes': [
            {'tapeType': 1, 'qty': null},
          ],
          'drawer': {'stored': 1, 'cap': 12, 'full': false, 'unopenedCount': 0},
          'entry': _entry,
        },
      ),
    );
    await api.purchase('tape3_1', idempotencyKey: 'key-1');
    final r = adapter.requests.single;
    expect(r.headers['Idempotency-Key'], 'key-1');
    expect(adapter.lastJson, {'productId': 'tape3_1'});
  });

  test('처리 중(409 IDEMPOTENCY_IN_PROGRESS)이면 같은 키로 다시 보낸다', () async {
    const busy = (
      409,
      {'code': 'IDEMPOTENCY_IN_PROGRESS', 'message': '잠시 뒤 다시 시도해 주세요'},
    );
    var n = 0;
    serve((r, _) => n++ < 2 ? busy : (201, _purchase));
    final r = await api.purchase('tape3_1', idempotencyKey: 'key-1');
    expect(r.credits, 90);
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests.map((x) => x.headers['Idempotency-Key']).toSet(), {
      'key-1',
    });

    // 멱등 키가 없는 요청은 다시 보내지 않는다
    serve((r, _) => busy);
    await expectLater(api.getWallet(), throwsA(isA<ApiException>()));
    expect(adapter.requests, hasLength(1));
  });

  test('오류 본문 → ApiException (code, message, extra)', () async {
    serve(
      (r, _) => (
        402,
        {'code': 'INSUFFICIENT_CREDITS', 'message': '크레딧이 부족해요', 'need': 20},
      ),
    );
    await expectLater(
      api.purchase('tape5_5', idempotencyKey: 'k'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 402)
            .having((e) => e.code, 'code', ApiErrorCode.insufficientCredits)
            .having((e) => e.extra['need'], 'need', 20),
      ),
    );
  });

  test('계약서 모양이 아닌 5xx는 서버 오류', () async {
    serve((r, _) => (502, '<html>Bad Gateway</html>'));
    await expectLater(
      api.getMe(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isServerError, 'server', isTrue)
            .having((e) => e.code, 'code', ApiErrorCode.internalError),
      ),
    );
  });

  test('연결 실패·타임아웃은 네트워크 오류 (오프라인 배너)', () async {
    serve(
      (r, _) => throw DioException.connectionError(
        requestOptions: r,
        reason: 'refused',
      ),
    );
    await expectLater(
      api.getMe(),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'network', isTrue),
      ),
    );
    serve(
      (r, _) => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: r,
      ),
    );
    await expectLater(
      api.getMe(),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'network', isTrue),
      ),
    );
  });

  test('204 빈 응답', () async {
    serve((r, _) => (204, null));
    await api.deleteShelfItem('t 1');
    expect(adapter.requests.single.uri.path, '/api/shelf/items/t%201');
    expect(adapter.requests.single.method, 'DELETE');
  });
}
