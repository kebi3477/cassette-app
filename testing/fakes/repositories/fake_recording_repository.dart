import 'package:tapeletter_app/data/repositories/recording_repository.dart';
import 'package:tapeletter_app/domain/models/recording.dart';
import 'package:tapeletter_app/domain/models/tape_type.dart';
import 'package:tapeletter_app/utils/result.dart';

/// 업로드·변환 결과와 시간을 시험마다 정하는 가짜.
class FakeRecordingRepository implements RecordingRepository {
  FakeRecordingRepository({
    this.uploadDelay = Duration.zero,
    this.convertDelay = const Duration(milliseconds: 200),
    this.failUpload = false,
    this.failConvert = false,
  });

  Duration uploadDelay;
  Duration convertDelay;
  bool failUpload;
  bool failConvert;
  int uploads = 0;
  int converts = 0;
  int retries = 0;

  @override
  Future<Result<Recording>> upload({
    required String filePath,
    required TapeType type,
    required Duration duration,
  }) async {
    uploads++;
    await Future<void>.delayed(uploadDelay);
    if (failUpload) return Result.error(Exception('upload failed'));
    return Result.ok(
      Recording(
        id: 'r$uploads',
        type: type,
        duration: duration,
        status: RecordingStatus.processing,
      ),
    );
  }

  @override
  Future<Result<Recording>> convert(String recordingId) async {
    converts++;
    return _wait(recordingId);
  }

  @override
  Future<Result<Recording>> retry(String recordingId) async {
    retries++;
    return _wait(recordingId);
  }

  Future<Result<Recording>> _wait(String recordingId) async {
    await Future<void>.delayed(convertDelay);
    if (failConvert) return Result.error(Exception('convert failed'));
    return Result.ok(
      Recording(
        id: recordingId,
        type: TapeType.s15,
        duration: const Duration(seconds: 12),
        status: RecordingStatus.ready,
        previewUrl: 'https://example.com/$recordingId.m4a',
      ),
    );
  }
}
