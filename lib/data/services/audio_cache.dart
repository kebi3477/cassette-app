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
  static String fileName(String deliveryId) =>
      '${deliveryId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.audio';

  Future<File> _file(String id) async =>
      File('${(await _dir()).path}/${fileName(id)}');

  @override
  Future<File?> find(String deliveryId) async {
    final f = await _file(deliveryId);
    return await f.exists() && await f.length() > 0 ? f : null;
  }

  @override
  Future<File> save(String deliveryId, String url) async {
    final f = await _file(deliveryId);
    // 다 받은 뒤에 이름을 바꿔, 끊긴 파일이 캐시로 남지 않게 한다.
    final part = File('${f.path}.part');
    try {
      await _dio.download(url, part.path);
      return await part.rename(f.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  @override
  Future<void> remove(String deliveryId) async {
    final f = await _file(deliveryId);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> clear() async {
    final d = await _dir();
    if (await d.exists()) await d.delete(recursive: true);
  }
}
