import '../../domain/models/share_link.dart';
import '../../utils/result.dart';

/// 링크로 받은 테이프 (`/share/{token}`).
///
/// 오류는 [ApiException]의 `code`(`LINK_TAKEN` · `LINK_EXPIRED` · `LINK_OWN` +`url` · `LINK_NOT_FOUND`)로 준다.
abstract class ShareRepository {
  Future<Result<ShareLink>> open(String token);

  /// 받기 🔑 → "분류 안 함" 맨 위, 서로 친구
  Future<Result<ClaimedTape>> claim(String token);
}
