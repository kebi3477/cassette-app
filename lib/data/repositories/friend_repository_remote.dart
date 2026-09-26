import '../../domain/models/blocked_user.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/friend_tapes.dart';
import '../../utils/result.dart';
import '../model/mappers.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'friend_repository.dart';

class FriendRepositoryRemote extends FriendRepository {
  FriendRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<Friend>>> getFriends() => guard(
    () async =>
        (await _api.getFriends()).items.map((f) => f.toDomain()).toList(),
  );

  @override
  Future<Result<Friend>> setStarred(String friendId, bool starred) async {
    final r = await guard(
      () async =>
          (await _api.patchFriend(friendId, starred: starred)).toDomain(),
    );
    if (r is Ok) notifyListeners();
    return r;
  }

  @override
  Future<Result<Friend>> setNickname(String friendId, String? nickname) async {
    final v = nickname?.trim();
    final r = await guard(
      () async => (await _api.setFriendNickname(
        friendId,
        v == null || v.isEmpty ? null : v,
      )).toDomain(),
    );
    // 별명은 서랍·보낸 테이프에도 보이므로 다시 불러오게 알린다.
    if (r is Ok) notifyListeners();
    return r;
  }

  @override
  Future<Result<FriendTapes>> getFriendTapes(String friendId) =>
      guard(() async => (await _api.getFriendTapes(friendId)).toDomain());

  Future<Result<T>> _mutate<T>(Future<T> Function() call) async {
    final r = await guard(call);
    if (r is Ok) notifyListeners();
    return r;
  }

  @override
  Future<Result<void>> remove(String friendId) =>
      _mutate(() => _api.deleteFriend(friendId));

  @override
  Future<Result<BlockedUser>> block(String userId) =>
      _mutate(() async => (await _api.blockUser(userId)).toDomain());

  @override
  Future<Result<List<BlockedUser>>> getBlocked() => guard(
    () async =>
        (await _api.getBlocks()).items.map((b) => b.toDomain()).toList(),
  );

  @override
  Future<Result<void>> unblock(String userId) =>
      _mutate(() => _api.unblockUser(userId));
}
