import 'friend.dart';
import 'tape_item.dart';

/// 친구 화면 — 그 친구가 나에게 보낸 테이프 중 뜯은 것.
class FriendTapes {
  const FriendTapes({
    required this.friend,
    required this.items,
    required this.unopenedCount,
  });

  final Friend friend;
  final List<FriendTape> items;

  /// 아직 안 뜯은 소포 수 (서랍에서 뜯는다)
  final int unopenedCount;
}

class FriendTape {
  const FriendTape({required this.item, required this.where});

  final TapeItem item;

  /// 들어 있는 칸 이름 (없으면 "분류 안 함")
  final String where;
}
