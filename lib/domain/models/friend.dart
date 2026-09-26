/// 친구 — logic.js `friends[]` (`{ name, star, last, alias }`).
///
/// [name]은 화면에 보이는 이름(별명이 있으면 별명, `nickname ?? name`),
/// [originalName]은 상대가 정한 원래 이름이다. 테이프 라벨처럼 상대가 보는 곳은 원래 이름을 쓴다.
class Friend {
  const Friend({
    required this.id,
    required this.name,
    String? originalName,
    this.nickname,
    required this.starred,
    this.lastAt,
  }) : originalName = originalName ?? name;

  final String id;

  /// 보이는 이름 (`f.alias || f.name`)
  final String name;

  /// 원래 이름 (`f.orig`는 별명이 있을 때만 옆에 회색으로)
  final String originalName;

  /// 내가 붙인 별명 (없으면 null)
  final String? nickname;

  /// 즐겨찾기
  final bool starred;

  /// 마지막으로 주고받은 날짜
  final DateTime? lastAt;

  /// 목록 행의 작은 회색 원래 이름 — 별명이 있을 때만
  String? get originalHint => nickname == null ? null : originalName;

  Friend copyWith({bool? starred, DateTime? lastAt}) => Friend(
    id: id,
    name: name,
    originalName: originalName,
    nickname: nickname,
    starred: starred ?? this.starred,
    lastAt: lastAt ?? this.lastAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Friend &&
      other.id == id &&
      other.name == name &&
      other.originalName == originalName &&
      other.nickname == nickname &&
      other.starred == starred &&
      other.lastAt == lastAt;

  @override
  int get hashCode =>
      Object.hash(id, name, originalName, nickname, starred, lastAt);
}
