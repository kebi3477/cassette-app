import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// 오디오 재생. 실제 구현은 [JustAudioPlayerService].
abstract class AudioPlayerService {
  /// 파일 경로나 URL을 불러오고 길이를 준다.
  Future<Duration?> load(String source);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> stop();

  Stream<Duration> get position;

  /// 끝까지 재생했을 때.
  Stream<void> get completed;

  Future<void> dispose();
}

class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService() {
    _stateSub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _completed.add(null);
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completed = StreamController.broadcast();
  late final StreamSubscription<PlayerState> _stateSub;

  @override
  Future<Duration?> load(String source) {
    if (source.startsWith('asset:///')) {
      return _player.setAsset(source.substring('asset:///'.length));
    }
    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _player.setUrl(source);
    }
    return _player.setFilePath(source);
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    // play()는 재생이 끝날 때까지 기다리므로 기다리지 않는다.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async {
    await _stateSub.cancel();
    await _completed.close();
    await _player.dispose();
  }
}
