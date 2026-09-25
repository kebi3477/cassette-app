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
  Future<Result<FriendTapes>> getFriendTapes(String friendId) =>
      guard(() async => (await _api.getFriendTapes(friendId)).toDomain());
}
