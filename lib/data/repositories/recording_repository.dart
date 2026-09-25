import '../../domain/models/recording.dart';
import '../../domain/models/tape_type.dart';
import '../../utils/result.dart';

/// 녹음 파일 업로드와 "테이프 소리" 변환.
abstract class RecordingRepository {
  /// 녹음 원본을 올린다. 서버는 받는 즉시 변환 작업을 큐에 넣는다.
  Future<Result<Recording>> upload({
    required String filePath,
    required TapeType type,
    required Duration duration,
  });

  /// 변환이 끝날 때까지 기다린다. 성공하면 `status == ready`와 미리 듣기 주소를 준다.
  Future<Result<Recording>> convert(String recordingId);
}
