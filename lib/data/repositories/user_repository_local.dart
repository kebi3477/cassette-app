import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../services/local/local_store.dart';
import 'user_repository.dart';

class UserRepositoryLocal implements UserRepository {
  UserRepositoryLocal(this._store);

  final LocalStore _store;

  @override
  Future<Result<User>> getMe() async => Result.ok(_store.me);

  @override
  Future<Result<User>> updateName(String name) async {
    final trimmed = name.trim();
    final next = trimmed.isEmpty
        ? '민경'
        : String.fromCharCodes(trimmed.runes.take(User.maxNameLength));
    _store.me = User(id: _store.me.id, name: next);
    return Result.ok(_store.me);
  }
}
