import '../../domain/models/recording.dart';
import '../../domain/models/tape_type.dart';
import '../../utils/result.dart';
import '../model/api_error.dart';
import '../model/mappers.dart';
import '../model/recording_dto.dart';
import '../services/api/api_client.dart';
import '../services/upload_service.dart';
import 'repository_guard.dart';
import 'recording_repository.dart';

class RecordingRepositoryRemote implements RecordingRepository {
  RecordingRepositoryRemote(
    this._api,
    this._uploads, {
    this.pollInterval = const Duration(seconds: 1),
    this.timeout = const Duration(minutes: 2),
  });

  final ApiClient _api;
  final UploadService _uploads;

  /// 계약서: 확인 화면이 1초 간격으로 부른다.
  final Duration pollInterval;
  final Duration timeout;

  @override
  Future<Result<Recording>> upload({
    required String filePath,
    required TapeType type,
    required Duration duration,
  }) => guard(() async {
    final created = await _api.createRecording(
      CreateRecordingRequest(
        tapeType: type.minutes,
        durationMs: duration.inMilliseconds,
      ),
    );
    await _uploads.upload(created.upload, filePath);
    return (await _api.completeRecording(created.id)).toDomain();
  });

  @override
  Future<Result<Recording>> convert(String recordingId) =>
      guard(() => _poll(recordingId));

  @override
  Future<Result<Recording>> retry(String recordingId) => guard(() async {
    await _api.retryRecording(recordingId);
    return _poll(recordingId);
  });

  Future<Recording> _poll(String id) async {
    final started = DateTime.now();
    while (true) {
      await Future<void>.delayed(pollInterval);
      final r = (await _api.getRecording(id)).toDomain();
      if (r.status == RecordingStatus.ready) return r;
      if (r.status == RecordingStatus.failed) {
        throw const ApiException(
          status: 200,
          code: 'RECORDING_FAILED',
          message: '테이프로 바꾸지 못했어요',
        );
      }
      if (DateTime.now().difference(started) > timeout) {
        throw const ApiException(
          status: 0,
          code: 'RECORDING_TIMEOUT',
          message: '테이프로 바꾸지 못했어요',
        );
      }
    }
  }
}
