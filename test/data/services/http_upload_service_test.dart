import 'dart:io';

import 'package:cassette_app/data/model/api_error.dart';
import 'package:cassette_app/data/model/recording_dto.dart';
import 'package:cassette_app/data/services/http_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/services/fake_http_adapter.dart';

void main() {
  late Directory tmp;
  late File file;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('upload');
    file = File('${tmp.path}/a.m4a')..writeAsBytesSync([1, 2, 3, 4, 5]);
  });
  tearDown(() => tmp.delete(recursive: true));

  final ticket = UploadTicketDto(
    url: 'http://storage.test/dev-storage/rec/1?op=put&sig=abc',
    method: 'PUT',
    headers: const {'Content-Type': 'audio/mp4'},
    expiresAt: DateTime.utc(2026, 9, 25),
  );

  test('presigned PUT: upload.headers 그대로, 본문은 파일 바이트', () async {
    final adapter = FakeHttpAdapter((r, _) => (200, null));
    await HttpUploadService(dio: Dio()..httpClientAdapter = adapter)
        .upload(ticket, file.path);
    final r = adapter.requests.single;
    expect(r.method, 'PUT');
    expect(r.uri.toString(), ticket.url);
    expect(r.headers['Content-Type'], 'audio/mp4');
    expect(r.headers.containsKey('Authorization'), isFalse);
    expect(adapter.bodies.single, [1, 2, 3, 4, 5]);
  });

  test('저장소가 거절하면 UPLOAD_FAILED, 연결이 안 되면 네트워크 오류', () async {
    var adapter = FakeHttpAdapter((r, _) => (403, 'signature mismatch'));
    await expectLater(
      HttpUploadService(dio: Dio()..httpClientAdapter = adapter)
          .upload(ticket, file.path),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'UPLOAD_FAILED'),
      ),
    );
    adapter = FakeHttpAdapter(
      (r, _) =>
          throw DioException.connectionError(requestOptions: r, reason: 'x'),
    );
    await expectLater(
      HttpUploadService(dio: Dio()..httpClientAdapter = adapter)
          .upload(ticket, file.path),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'network', isTrue),
      ),
    );
  });
}
