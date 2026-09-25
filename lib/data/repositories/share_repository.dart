import '../../domain/models/share_link.dart';
import '../model/api_error.dart';
import '../../utils/result.dart';

/// 링크로 받은 테이프 (`/share/{token}`).
///
/// 오류는 [ApiException]의 `code`(`LINK_TAKEN` · `LINK_EXPIRED` · `LINK_OWN` +`url` · `LINK_NOT_FOUND`)로 준다.
abstract class ShareRepository {
  /// 링크 열기 (`GET /share/{token}`) — 받지는 않는다.
  Future<Result<ShareLink>> open(String token);

  /// 방금 연 링크 (소포 화면이 다시 부르지 않게)
  ShareLink? peek(String token);

  /// 받기 🔑 → "분류 안 함" 맨 위, 서로 친구
  Future<Result<ClaimedTape>> claim(String token);
}

/// 링크 오류 → 오류 화면(`leOn`) 종류와 own일 때 다시 공유할 주소. 링크 오류가 아니면 null.
(LinkErrorKind, String?)? linkErrorOf(Object e) {
  if (e is! ApiException) return null;
  return switch (e.code) {
    ApiErrorCode.linkTaken => (LinkErrorKind.taken, null),
    ApiErrorCode.linkExpired => (LinkErrorKind.expired, null),
    ApiErrorCode.linkOwn => (LinkErrorKind.own, e.extra['url'] as String?),
    _ => null,
  };
}
