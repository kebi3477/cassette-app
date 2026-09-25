import '../../domain/models/recording.dart';
import '../../domain/models/tape_type.dart';
import '../../utils/result.dart';
import '../services/local/local_behavior.dart';
import '../services/local/local_store.dart';
import 'recording_repository.dart';

/// 서버 없이 업로드·변환을 흉내 낸다. 변환 결과는 원본 파일 그대로다.
class RecordingRepositoryLocal implements RecordingRepository {
  RecordingRepositoryLocal(this._store, this._behavior);

  final LocalStore _store;
  final LocalBehavior _behavior;
  final Map<String, Recording> _recordings = {};
  final Map<String, String> _files = {};

  @override
  Future<Result<Recording>> upload({
    required String filePath,
    required TapeType type,
    required Duration duration,
  }) async {
    await Future<void>.delayed(_behavior.uploadDelay);
    final rec = Recording(
      id: _store.nextId('r'),
      type: type,
      duration: duration,
      status: RecordingStatus.converting,
    );
    _recordings[rec.id] = rec;
    _files[rec.id] = filePath;
    return Result.ok(rec);
  }

  @override
  Future<Result<Recording>> convert(String recordingId) async {
    final rec = _recordings[recordingId];
    if (rec == null) return Result.error(Exception('녹음을 찾을 수 없어요'));
    if (_behavior.failsConvert) {
      await Future<void>.delayed(_behavior.convertFailDelay);
      _recordings[recordingId] = rec.copyWith(status: RecordingStatus.failed);
      return Result.error(Exception('테이프로 바꾸지 못했어요'));
    }
    await Future<void>.delayed(
      _behavior.slowConvert
          ? _behavior.convertSlowDelay
          : _behavior.convertDelay,
    );
    final ready = rec.copyWith(
      status: RecordingStatus.ready,
      previewUrl: _files[recordingId],
    );
    _recordings[recordingId] = ready;
    return Result.ok(ready);
  }
}
