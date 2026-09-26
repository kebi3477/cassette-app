import 'dart:io';
import 'dart:typed_data';

import 'package:tapeletter_app/data/model/shelf_dto.dart';
import 'package:tapeletter_app/data/repositories/shelf_repository_remote.dart';
import 'package:tapeletter_app/data/services/api/api_client.dart';
import 'package:tapeletter_app/data/services/audio_cache.dart';
import 'package:tapeletter_app/domain/models/tape_audio.dart';
import 'package:tapeletter_app/utils/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/services/fake_http_adapter.dart';

/// 재생 URL과 지우기만 답하는 서버
class _AudioApi implements ApiClient {
  int audioCalls = 0;
  final List<String> deleted = [];

  @override
  String? accessToken;

  @override
  Future<AudioUrlDto> getDeliveryAudio(String id) async {
    audioCalls++;
    // 부를 때마다 다른 서명 URL (10분 만료)
    return AudioUrlDto(
      url: 'http://storage.test/dev-storage/$id?sig=$audioCalls',
      expiresAt: DateTime.utc(2026, 9, 25),
      durationMs: 34000,
    );
  }

  @override
  Future<void> deleteShelfItem(String id) async => deleted.add(id);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// 응답 Content-Type을 바꿔 주는 어댑터
class _Typed implements HttpClientAdapter {
  _Typed(this._inner, this._type);

  final HttpClientAdapter _inner;
  final String _type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    final r = await _inner.fetch(o, s, c);
    r.headers[Headers.contentTypeHeader] = [_type];
    return r;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;
  late FakeHttpAdapter storage;
  late FileAudioCache cache;
  late _AudioApi api;
  late ShelfRepositoryRemote shelf;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('tapes');
    storage = FakeHttpAdapter((r, _) => (200, 'RIFF-${r.uri.path}'));
    cache = FileAudioCache(
      root: Directory('${tmp.path}/tapes'),
      dio: Dio()..httpClientAdapter = storage,
    );
    api = _AudioApi();
    shelf = ShelfRepositoryRemote(api, cache: cache);
  });
  tearDown(() => tmp.delete(recursive: true));

  test('처음엔 받아서 파일로, 다음부터는 서버에 묻지 않고 그 파일', () async {
    final a = (await shelf.audioUrl('d1') as Ok<TapeAudio>).value;
    expect(a.url, startsWith(tmp.path));
    expect(a.duration, const Duration(seconds: 34));
    expect(File(a.url).readAsStringSync(), 'RIFF-/dev-storage/d1');
    expect(api.audioCalls, 1);

    final b = (await shelf.audioUrl('d1') as Ok<TapeAudio>).value;
    expect(b.url, a.url, reason: 'URL이 아니라 delivery id가 키');
    expect(api.audioCalls, 1);
    expect(storage.requests, hasLength(1));
  });

  test('내려받기가 실패하면 URL로 재생하고 캐시에 남기지 않는다', () async {
    storage = FakeHttpAdapter((r, _) => (500, 'x'));
    cache = FileAudioCache(
      root: Directory('${tmp.path}/tapes'),
      dio: Dio()..httpClientAdapter = storage,
    );
    shelf = ShelfRepositoryRemote(api, cache: cache);
    final a = (await shelf.audioUrl('d2') as Ok<TapeAudio>).value;
    expect(a.url, startsWith('http://storage.test/'));
    expect(await cache.find('d2'), isNull);
  });

  test('테이프를 지우면 그 파일도 지운다', () async {
    await shelf.audioUrl('d3');
    expect(await cache.find('d3'), isNotNull);
    await shelf.deleteItem('d3');
    expect(api.deleted, ['d3']);
    expect(await cache.find('d3'), isNull);
  });

  test('clear: 전부 지운다 (로그아웃·탈퇴)', () async {
    await shelf.audioUrl('d4');
    await shelf.audioUrl('d5');
    await cache.clear();
    expect(await cache.find('d4'), isNull);
    expect(await cache.find('d5'), isNull);
  });

  test('파일 이름은 경로를 벗어나지 않고, 확장자는 Content-Type을 따른다', () {
    expect(FileAudioCache.baseName('../../etc/passwd'), '______etc_passwd');
    expect(FileAudioCache.extensionFor('audio/wav'), 'wav');
    expect(FileAudioCache.extensionFor('audio/mp4; charset=binary'), 'm4a');
    expect(FileAudioCache.extensionFor(null), 'm4a');
  });

  test('저장소가 준 형식대로 확장자를 붙인다 (iOS 재생기)', () async {
    final wav = FileAudioCache(
      root: Directory('${tmp.path}/wav'),
      dio: Dio()..httpClientAdapter = _Typed(storage, 'audio/wav'),
    );
    final f = await wav.save('d9', 'http://storage.test/x');
    expect(f.path, endsWith('/d9.wav'));
    expect((await wav.find('d9'))?.path, f.path);
    await wav.remove('d9');
    expect(await wav.find('d9'), isNull);
  });
}
