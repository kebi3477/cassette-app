/// 녹음을 보낼 받는 사람 — logic.js `to` (`{ name, isNew? }`).
///
/// 기존 친구면 [friendId]가 있고, 새 친구(링크로 보내기)면 [isNew]가 참이다.
class Recipient {
  const Recipient.friend({required String this.friendId, required this.name})
    : isNew = false;

  const Recipient.newFriend({this.name = ''}) : friendId = null, isNew = true;

  final String? friendId;
  final String name;
  final bool isNew;

  Recipient withName(String name) => isNew
      ? Recipient.newFriend(name: name)
      : Recipient.friend(friendId: friendId!, name: name);

  @override
  bool operator ==(Object other) =>
      other is Recipient &&
      other.friendId == friendId &&
      other.name == name &&
      other.isNew == isNew;

  @override
  int get hashCode => Object.hash(friendId, name, isNew);
}
