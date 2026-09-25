import '../../domain/models/recording.dart';
import '../../domain/models/tape_type.dart';
import '../../utils/result.dart';

/// 녹음 파일 업로드와 "테이프 소리" 변환 (`/recordings`).
abstract class RecordingRepository {
  /// `POST /recordings` → presigned PUT 업로드 → `POST /recordings/{id}/complete`.
  /// 성공하면 `status == processing`인 녹음을 준다.
  Future<Result<Recording>> upload({
    required String filePath,
    required TapeType type,
    required Duration duration,
  });

  /// `GET /recordings/{id}`를 1초 간격으로 불러 `ready`나 `failed`가 될 때까지 기다린다.
  /// `ready`면 미리 듣기 주소와 실제 길이를 준다. `failed`면 오류.
  Future<Result<Recording>> convert(String recordingId);

  /// `POST /recordings/{id}/retry` 뒤 [convert]처럼 기다린다.
  Future<Result<Recording>> retry(String recordingId);
}
