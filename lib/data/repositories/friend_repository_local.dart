import '../../domain/models/friend.dart';
import '../../utils/result.dart';
import '../services/local/local_store.dart';
import 'friend_repository.dart';

class FriendRepositoryLocal extends FriendRepository {
  FriendRepositoryLocal(this._store);

  final LocalStore _store;

  @override
  Future<Result<List<Friend>>> getFriends() async =>
      Result.ok(List.unmodifiable(_store.friends));

  @override
  Future<Result<Friend>> setStarred(String friendId, bool starred) async {
    final i = _store.friends.indexWhere((f) => f.id == friendId);
    if (i < 0) return Result.error(Exception('친구를 찾을 수 없어요'));
    final next = _store.friends[i].copyWith(starred: starred);
    _store.friends = [..._store.friends]..[i] = next;
    notifyListeners();
    return Result.ok(next);
  }

  /// 보내기가 끝나면 받는 사람을 목록 맨 앞으로 올리고 날짜를 갱신한다 (logic.js `runSend`).
  void touch(String name, DateTime at) {
    final others = _store.friends.where((f) => f.name != name).toList();
    final me = _store.friends.where((f) => f.name == name).firstOrNull;
    final next =
        me?.copyWith(lastAt: at) ??
        Friend(id: _store.nextId('f'), name: name, starred: false, lastAt: at);
    _store.friends = [next, ...others];
    notifyListeners();
  }
}
