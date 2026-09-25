import 'friend.dart';
import 'tape_item.dart';
import 'tape_tag.dart';
import 'tape_type.dart';

/// `GET /share/{token}` 결과 — 뜯기 전 소포 화면(보낸 사람, 테이프 종류)을 그린다.
class ShareLink {
  const ShareLink({
    required this.token,
    required this.claimed,
    this.deliveryId,
    required this.senderName,
    this.senderId,
    required this.type,
    required this.duration,
    this.tag,
    required this.sentAt,
  });

  final String token;

  /// 내가 이미 받은 링크 → [deliveryId]로 서랍의 그 테이프를 연다
  final bool claimed;
  final String? deliveryId;
  final String senderName;
  final String? senderId;
  final TapeType type;
  final Duration duration;
  final TapeTag? tag;
  final DateTime sentAt;

  /// 받기 전 소포 — 아직 서랍에 없으므로 임시 id(`link:{token}`)
  TapeItem get parcel => TapeItem(
    id: 'link:$token',
    from: senderName,
    senderId: senderId,
    date: sentAt,
    type: type,
    duration: duration,
    tag: tag,
    opened: false,
    viaLink: true,
  );
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
