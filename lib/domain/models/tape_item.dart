import 'tape_type.dart';

/// 받은 테이프 한 개 — logic.js `TapeItem` / `InboxItem`.
class TapeItem {
  const TapeItem({
    required this.id,
    required this.from,
    required this.date,
    required this.type,
    this.tag,
    this.opened = true,
    this.viaLink = false,
  });

  final String id;

  /// 보낸 사람 이름
  final String from;

  /// 받은 날짜
  final DateTime date;
  final TapeType type;

  /// 칸 분류용 태그 (생일 · 축하 · 그냥)
  final String? tag;

  /// 소포를 뜯었는지. 칸에 들어간 테이프는 항상 참이다.
  final bool opened;

  /// 링크로 받았는지 ("N님과 친구가 되었어요" 칩)
  final bool viaLink;

  TapeItem copyWith({bool? opened}) => TapeItem(
    id: id,
    from: from,
    date: date,
    type: type,
    tag: tag,
    opened: opened ?? this.opened,
    viaLink: viaLink,
  );
}
