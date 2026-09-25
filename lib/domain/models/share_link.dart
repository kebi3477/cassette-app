import 'friend.dart';
import 'tape_item.dart';

/// `GET /share/{token}` 결과
class ShareLink {
  const ShareLink({
    required this.token,
    required this.claimed,
    this.deliveryId,
    required this.senderName,
  });

  final String token;

  /// 내가 이미 받은 링크 → [deliveryId]로 서랍의 그 테이프를 연다
  final bool claimed;
  final String? deliveryId;
  final String senderName;
}

/// `POST /share/{token}/claim` 결과
class ClaimedTape {
  const ClaimedTape({required this.item, this.friend});

  final TapeItem item;

  /// 서로 친구가 됐으면 그 친구 ("○○님과 친구가 되었어요")
  final Friend? friend;
}

/// 링크 오류 화면 (`leOn`) — `LINK_TAKEN` · `LINK_EXPIRED` · `LINK_OWN`
enum LinkErrorKind { taken, expired, own }
