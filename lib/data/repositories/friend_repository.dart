import 'package:flutter/foundation.dart';

import '../../domain/models/friend.dart';
import '../../domain/models/friend_tapes.dart';
import '../../utils/result.dart';

/// 친구 (`/friends`). 목록이 바뀌면 리스너에게 알린다.
abstract class FriendRepository extends ChangeNotifier {
  Future<Result<List<Friend>>> getFriends();

  Future<Result<Friend>> setStarred(String friendId, bool starred);

  /// 친구 화면 — 그 친구가 보낸 테이프 (`GET /friends/{userId}/tapes`)
  Future<Result<FriendTapes>> getFriendTapes(String friendId);

  /// 보내기 등 다른 곳에서 목록이 바뀌었을 때 화면에 다시 불러오라고 알린다.
  void invalidate() => notifyListeners();
}
