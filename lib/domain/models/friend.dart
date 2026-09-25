/// 친구 — logic.js `friends[]` (`{ name, star, last }`).
class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.starred,
    this.lastAt,
  });

  final String id;
  final String name;

  /// 즐겨찾기
  final bool starred;

  /// 마지막으로 주고받은 날짜
  final DateTime? lastAt;

  Friend copyWith({bool? starred, DateTime? lastAt}) => Friend(
    id: id,
    name: name,
    starred: starred ?? this.starred,
    lastAt: lastAt ?? this.lastAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Friend &&
      other.id == id &&
      other.name == name &&
      other.starred == starred &&
      other.lastAt == lastAt;

  @override
  int get hashCode => Object.hash(id, name, starred, lastAt);
}
