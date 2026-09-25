import 'json.dart';
import 'shelf_dto.dart';

/// `POST /deliveries` 요청 — `recipientId`와 `linkName` 중 하나만.
class CreateDeliveryRequest {
  const CreateDeliveryRequest({
    required this.recordingId,
    this.recipientId,
    this.linkName,
    required this.tag,
  }) : assert((recipientId == null) != (linkName == null));

  final String recordingId;
  final String? recipientId;
  final String? linkName;

  /// `birthday` · `congrats` · `thinking`
  final String tag;

  Json toJson() => {
    'recordingId': recordingId,
    'recipientId': ?recipientId,
    'linkName': ?linkName,
    'tag': tag,
  };
}

/// 보낸 테이프 — 계약서 §2 SentTape.
/// `status`: `link_pending | link_expired | unopened | opened`
class SentTapeDto {
  const SentTapeDto({
    required this.id,
    this.recipient,
    this.linkName,
    required this.tapeType,
    required this.durationMs,
    required this.tag,
    required this.sentAt,
    required this.status,
    this.claimedAt,
    this.openedAt,
    this.share,
  });

  final String id;
  final UserRefDto? recipient;
  final String? linkName;
  final int tapeType;
  final int durationMs;
  final String? tag;
  final DateTime sentAt;
  final String status;
  final DateTime? claimedAt;
  final DateTime? openedAt;
  final ShareLinkDto? share;

  factory SentTapeDto.fromJson(Json j) => SentTapeDto(
    id: j['id'] as String,
    recipient: j['recipient'] == null
        ? null
        : UserRefDto.fromJson(j['recipient'] as Json),
    linkName: j['linkName'] as String?,
    tapeType: j['tapeType'] as int,
    durationMs: j['durationMs'] as int,
    tag: j['tag'] as String?,
    sentAt: parseDate(j['sentAt']),
    status: j['status'] as String,
    claimedAt: parseDateOrNull(j['claimedAt']),
    openedAt: parseDateOrNull(j['openedAt']),
    share: j['share'] == null
        ? null
        : ShareLinkDto.fromJson(j['share'] as Json),
  );

  Json toJson() => {
    'id': id,
    'recipient': recipient?.toJson(),
    'linkName': linkName,
    'tapeType': tapeType,
    'durationMs': durationMs,
    'tag': tag,
    'sentAt': dateToJson(sentAt),
    'status': status,
    'claimedAt': claimedAt == null ? null : dateToJson(claimedAt!),
    'openedAt': openedAt == null ? null : dateToJson(openedAt!),
    'share': share?.toJson(),
  };
}

class ShareLinkDto {
  const ShareLinkDto({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  factory ShareLinkDto.fromJson(Json j) => ShareLinkDto(
    url: j['url'] as String,
    expiresAt: parseDate(j['expiresAt']),
  );

  Json toJson() => {'url': url, 'expiresAt': dateToJson(expiresAt)};
}
