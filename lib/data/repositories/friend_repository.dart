import 'package:flutter/foundation.dart';

import '../../domain/models/friend.dart';
import '../../utils/result.dart';

/// 친구 목록. 즐겨찾기 먼저 보여주는 정렬은 화면에서 한다.
///
/// 보내기 등으로 목록이 바뀌면 리스너에게 알린다.
abstract class FriendRepository extends ChangeNotifier {
  Future<Result<List<Friend>>> getFriends();

  Future<Result<Friend>> setStarred(String friendId, bool starred);
}
