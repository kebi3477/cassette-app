import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 마이크 녹음. 실제 구현은 [RecordRecorderService].
abstract class RecorderService {
  /// 마이크 권한. [request]가 참이면 시스템 권한 창을 띄운다.
  Future<bool> hasPermission({bool request = true});

  /// 새 파일에 녹음을 시작한다.
  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  /// 녹음을 끝내고 파일 경로를 준다.
  Future<String?> stop();

  /// 녹음을 버린다.
  Future<void> cancel();

  /// 전화 등으로 시스템이 녹음을 멈췄을 때.
  Stream<void> get onInterrupted;

  Future<void> dispose();
}

/// `record` 패키지로 AAC(m4a) 64kbps 모노 녹음 — ARCHITECTURE.md §5.
class RecordRecorderService implements RecorderService {
  RecordRecorderService() {
    _stateSub = _recorder.onStateChanged().listen((state) {
      // 우리가 pause()를 부르지 않았는데 멈췄다면 시스템이 끊은 것이다.
      if (state == RecordState.pause && !_pausing) _interrupted.add(null);
    });
  }

  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<void> _interrupted = StreamController.broadcast();
  late final StreamSubscription<RecordState> _stateSub;
  bool _pausing = false;

  static const config = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 64000,
    sampleRate: 44100,
    numChannels: 1,
  );

  @override
  Future<bool> hasPermission({bool request = true}) =>
      _recorder.hasPermission(request: request);

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(config, path: path);
  }

  @override
  Future<void> pause() async {
    _pausing = true;
    try {
      await _recorder.pause();
    } finally {
      _pausing = false;
    }
  }

  @override
  Future<void> resume() => _recorder.resume();

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Stream<void> get onInterrupted => _interrupted.stream;

  @override
  Future<void> dispose() async {
    await _stateSub.cancel();
    await _interrupted.close();
    await _recorder.dispose();
  }
}
