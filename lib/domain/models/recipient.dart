/// 녹음을 보낼 받는 사람 — logic.js `to` (`{ name, isNew? }`).
///
/// 기존 친구면 [friendId]가 있고, 새 친구(링크로 보내기)면 [isNew]가 참이다.
class Recipient {
  const Recipient.friend({
    required String this.friendId,
    required String this._name,
  }) : linkName = null,
       isNew = false;

  /// 새 친구 — 이름은 선택 입력. 비우면 [linkName]이 null이고 "새 친구"로 보인다 (v3).
  const Recipient.newFriend({this.linkName})
    : friendId = null,
      _name = null,
      isNew = true;

  /// 이름을 비운 새 친구의 표시 이름
  static const unnamed = '새 친구';

  final String? friendId;
  final String? _name;

  /// 새 친구에게 적은 이름 (`POST /deliveries`의 `linkName`, 비우면 보내지 않는다)
  final String? linkName;
  final bool isNew;

  /// 테이프 라벨·화면에 적히는 이름
  String get name => _name ?? linkName ?? unnamed;

  @override
  bool operator ==(Object other) =>
      other is Recipient &&
      other.friendId == friendId &&
      other.name == name &&
      other.linkName == linkName &&
      other.isNew == isNew;

  @override
  int get hashCode => Object.hash(friendId, name, isNew);
}
