import 'dart:async';

import 'package:cassette_app/data/services/audio_player_service.dart';

/// 소리 없이 재생 상태만 흉내 내는 가짜 플레이어.
class FakeAudioPlayerService implements AudioPlayerService {
  FakeAudioPlayerService({this.duration = const Duration(seconds: 12)});

  Duration? duration;
  String? loaded;
  bool playing = false;
  final List<String> calls = [];
  final StreamController<Duration> _position = StreamController.broadcast();
  final StreamController<void> _completed = StreamController.broadcast();

  void emitPosition(Duration d) => _position.add(d);

  void complete() {
    playing = false;
    _completed.add(null);
  }

  /// 불러오기를 실패하게 한다 (재생 불러오기 실패 `vErrorOn`)
  bool failLoad = false;

  @override
  Future<Duration?> load(String source) async {
    calls.add('load');
    if (failLoad) throw Exception('load failed');
    loaded = source;
    return duration;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async => calls.add('seek');

  @override
  Future<void> stop() async {
    calls.add('stop');
    playing = false;
  }

  bool loopOne = false;

  @override
  Future<void> setLoopOne(bool on) async => loopOne = on;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async {
    await _position.close();
    await _completed.close();
  }
}
