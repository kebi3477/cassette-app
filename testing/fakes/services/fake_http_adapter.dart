import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 요청을 기록하고 정해 둔 응답을 돌려주는 dio 어댑터 (서버 없이 HTTP 구현 시험).
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  /// 요청 → (상태, 본문). 본문이 Map/List면 JSON, String이면 그대로, null이면 빈 본문.
  /// [DioException]을 던지면 연결 오류처럼 된다.
  final (int, Object?) Function(RequestOptions r, List<int> body) handler;

  final List<RequestOptions> requests = [];
  final List<List<int>> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        bytes.addAll(c);
      }
    }
    requests.add(options);
    bodies.add(bytes);
    final (status, body) = handler(options, bytes);
    final isJson = body is Map || body is List;
    final text = body == null
        ? ''
        : isJson
        ? jsonEncode(body)
        : '$body';
    return ResponseBody.fromString(
      text,
      status,
      headers: {
        Headers.contentTypeHeader: [
          isJson ? 'application/json; charset=utf-8' : 'text/plain',
        ],
      },
    );
  }

  /// 마지막 요청 본문 JSON
  Object? get lastJson =>
      bodies.last.isEmpty ? null : jsonDecode(utf8.decode(bodies.last));

  @override
  void close({bool force = false}) {}
}
