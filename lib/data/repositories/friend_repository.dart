import 'package:flutter/foundation.dart';

import '../../domain/models/blocked_user.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/friend_tapes.dart';
import '../../utils/result.dart';

/// 친구 (`/friends`). 목록이 바뀌면 리스너에게 알린다.
abstract class FriendRepository extends ChangeNotifier {
  Future<Result<List<Friend>>> getFriends();

  Future<Result<Friend>> setStarred(String friendId, bool starred);

  /// 별명 (`PATCH /friends/{userId} { nickname }`) — null·빈 값이면 원래 이름으로
  Future<Result<Friend>> setNickname(String friendId, String? nickname);

  /// 친구 화면 — 그 친구가 보낸 테이프 (`GET /friends/{userId}/tapes`)
  Future<Result<FriendTapes>> getFriendTapes(String friendId);

  /// 목록에서 빼기 (`DELETE /friends/{userId}`)
  Future<Result<void>> remove(String friendId);

  /// 차단 (`POST /friends/{userId}/block`) — 목록에서 빠진다.
  Future<Result<BlockedUser>> block(String userId);

  /// 차단한 친구 (`GET /friends/blocks`)
  Future<Result<List<BlockedUser>>> getBlocked();

  /// 차단 해제 — 친구였다면 즐겨찾기·lastAt까지 돌아온다.
  Future<Result<void>> unblock(String userId);

  /// 보내기 등 다른 곳에서 목록이 바뀌었을 때 화면에 다시 불러오라고 알린다.
  void invalidate() => notifyListeners();
}
