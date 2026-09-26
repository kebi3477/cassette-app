import 'dart:async';

import 'package:tapeletter_app/data/services/recorder_service.dart';

/// 마이크 없이 녹음 흐름을 시험하는 가짜 녹음기.
class FakeRecorderService implements RecorderService {
  FakeRecorderService({this.granted = true, this.grantOnRequest = true});

  /// 이미 권한이 있는지
  bool granted;

  /// 권한 창에서 허용할지
  bool grantOnRequest;

  String path = '/tmp/fake_recording.m4a';
  final List<String> calls = [];
  final StreamController<void> _interrupted = StreamController.broadcast();

  /// 전화가 온 것처럼 시스템이 녹음을 멈춘다.
  void interrupt() => _interrupted.add(null);

  @override
  Future<bool> hasPermission({bool request = true}) async {
    calls.add('hasPermission(request: $request)');
    if (!granted && request) granted = grantOnRequest;
    return granted;
  }

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<String?> stop() async {
    calls.add('stop');
    return path;
  }

  @override
  Future<void> cancel() async => calls.add('cancel');

  @override
  Stream<void> get onInterrupted => _interrupted.stream;

  @override
  Future<void> dispose() => _interrupted.close();
}
