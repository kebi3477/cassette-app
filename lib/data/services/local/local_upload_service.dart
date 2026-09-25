import '../../model/recording_dto.dart';
import '../upload_service.dart';
import 'local_store.dart';

/// 파일을 실제로 올리지 않고, presigned URL과 파일 경로만 기억한다.
class LocalUploadService implements UploadService {
  LocalUploadService(this._store);

  final LocalStore _store;

  @override
  Future<void> upload(UploadTicketDto ticket, String filePath) async {
    _store.uploads[ticket.url] = filePath;
  }
}
