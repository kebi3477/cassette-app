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
        tapeType: type.code,
        durationMs: duration.inMilliseconds,
      ),
    );
    await _uploads.upload(created.upload, filePath);
    return (await _complete(created.id)).toDomain();
  });

  /// 업로드 완료 알림. 일시적인 오류면 몇 번 더 보낸다 (서버는 이미 넘어간 상태면 그대로 준다).
  Future<RecordingDto> _complete(String id) async {
    for (var i = 0; ; i++) {
      try {
        return await _api.completeRecording(id);
      } on ApiException catch (e) {
        if (!isTransient(e) || i >= completeRetries) rethrow;
        await Future<void>.delayed(pollInterval);
      }
    }
  }

  /// complete를 다시 보내는 횟수
  static const completeRetries = 3;

  /// 잠깐 지나가는 오류 — 연결 끊김·타임아웃, 서버 5xx, 요청 제한.
  /// 변환 실패 화면은 서버가 `status: failed`라고 할 때만 띄운다.
  static bool isTransient(ApiException e) =>
      e.isNetwork || e.isServerError || e.status == 408 || e.status == 429;

  @override
  Future<Result<Recording>> convert(String recordingId) =>
      guard(() => _poll(recordingId));

  @override
  Future<Result<Recording>> retry(String recordingId) => guard(() async {
    await _api.retryRecording(recordingId);
    return _poll(recordingId);
  });

  Future<Recording> _poll(String id) async {
    // 기다린 시간은 폴링 간격으로 센다 (요청 시간은 빼고, 최대 [timeout])
    var waited = Duration.zero;
    Object? lastError;
    while (true) {
      await Future<void>.delayed(pollInterval);
      waited += pollInterval;
      if (waited > timeout) {
        throw ApiException(
          status: 0,
          code: 'RECORDING_TIMEOUT',
          message: '테이프로 바꾸지 못했어요',
          extra: {'lastError': ?lastError?.toString()},
        );
      }
      final RecordingDto dto;
      try {
        dto = await _api.getRecording(id);
      } on ApiException catch (e) {
        // 일시적인 오류는 실패가 아니다. 다음 폴링에서 다시 묻는다.
        if (!isTransient(e)) rethrow;
        lastError = e;
        continue;
      }
      final r = dto.toDomain();
      switch (r.status) {
        case RecordingStatus.ready:
          return r;
        case RecordingStatus.failed:
          throw const ApiException(
            status: 200,
            code: 'RECORDING_FAILED',
            message: '테이프로 바꾸지 못했어요',
          );
        case RecordingStatus.uploading:
          // complete가 서버에 닿지 않았다 → 다시 알린다 (이미 넘어갔으면 서버가 그대로 준다)
          try {
            await _api.completeRecording(id);
          } on ApiException catch (e) {
            if (!isTransient(e)) rethrow;
          }
        case RecordingStatus.processing:
          break;
      }
    }
  }
}
