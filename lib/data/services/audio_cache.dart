import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 받은 테이프 오디오 캐시 — 재생 URL은 10분짜리라 **delivery id**를 키로 저장한다.
///
/// 한 번 받은 파일은 다음부터 서버에 묻지 않고 바로 재생한다.
/// 테이프를 지우거나 로그아웃·탈퇴하면 지운다.
abstract class AudioCache {
  /// 저장된 파일. 없으면 null.
  Future<File?> find(String deliveryId);

  /// [url]에서 받아 저장하고 그 파일을 준다.
  Future<File> save(String deliveryId, String url);

  Future<void> remove(String deliveryId);

  Future<void> clear();
}

/// 앱 캐시 폴더(`<cache>/tapes/`)에 파일로 둔다.
class FileAudioCache implements AudioCache {
  FileAudioCache({this._root, Dio? dio}) : _dio = dio ?? Dio();

  Directory? _root;
  final Dio _dio;

  Future<Directory> _dir() async {
    final d = _root ??= Directory(
      '${(await getApplicationCacheDirectory()).path}/tapes',
    );
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// id는 UUID지만, 경로를 벗어나지 않게 파일 이름에 쓸 수 있는 글자만 남긴다.
  static String baseName(String deliveryId) =>
      deliveryId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  /// iOS 재생기(AVPlayer)는 파일 확장자로 형식을 알아내므로 Content-Type에 맞춘다.
  static String extensionFor(String? contentType) {
    final t = (contentType ?? '').split(';').first.trim().toLowerCase();
    return switch (t) {
      'audio/wav' || 'audio/x-wav' || 'audio/wave' || 'audio/vnd.wave' => 'wav',
      'audio/mpeg' || 'audio/mp3' => 'mp3',
      'audio/aac' || 'audio/x-aac' => 'aac',
      _ => 'm4a', // audio/mp4 · audio/m4a · audio/x-m4a (녹음 형식)
    };
  }

  Future<List<File>> _files(String id) async {
    final prefix = '${baseName(id)}.';
    final d = await _dir();
    return [
      await for (final e in d.list())
        if (e is File &&
            e.uri.pathSegments.last.startsWith(prefix) &&
            !e.path.endsWith('.part'))
          e,
    ];
  }

  @override
  Future<File?> find(String deliveryId) async {
    for (final f in await _files(deliveryId)) {
      if (await f.length() > 0) return f;
    }
    return null;
  }

  @override
  Future<File> save(String deliveryId, String url) async {
    final d = await _dir();
    // 다 받은 뒤에 이름을 바꿔, 끊긴 파일이 캐시로 남지 않게 한다.
    final part = File('${d.path}/${baseName(deliveryId)}.part');
    try {
      final r = await _dio.download(url, part.path);
      final ext = extensionFor(r.headers.value(Headers.contentTypeHeader));
      return await part.rename('${d.path}/${baseName(deliveryId)}.$ext');
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  @override
  Future<void> remove(String deliveryId) async {
    for (final f in await _files(deliveryId)) {
      await f.delete();
    }
  }

  @override
  Future<void> clear() async {
    final d = await _dir();
    if (await d.exists()) await d.delete(recursive: true);
  }
}
