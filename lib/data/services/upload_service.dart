import '../model/recording_dto.dart';

/// 녹음 파일을 presigned URL로 직접 올린다 (`POST /recordings`의 `upload`).
abstract class UploadService {
  Future<void> upload(UploadTicketDto ticket, String filePath);
}
