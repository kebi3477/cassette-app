import 'tape_type.dart';

/// 보낸 테이프 — logic.js `sent[]` (`{ to, date, type, link?, claimed?, opened? }`).
class SentTape {
  const SentTape({
    required this.id,
    required this.to,
    required this.date,
    required this.type,
    this.link = false,
    this.claimed = false,
    this.openedAt,
    this.shareUrl,
  });

  final String id;

  /// 받는 사람 이름 (링크로 보냈으면 보낼 때 적은 이름)
  final String to;
  final DateTime date;
  final TapeType type;

  /// 새 친구에게 링크로 보냈는지
  final bool link;

  /// 링크를 누군가 받았는지
  final bool claimed;

  /// 상대가 들은 날짜
  final DateTime? openedAt;

  /// 링크로 보냈을 때 공유할 주소
  final Uri? shareUrl;
}
