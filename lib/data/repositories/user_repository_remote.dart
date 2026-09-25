import '../../domain/models/me.dart';
import '../../utils/result.dart';
import '../model/mappers.dart';
import '../model/me_dto.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'user_repository.dart';

class UserRepositoryRemote extends UserRepository {
  UserRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<Result<Me>> getMe() =>
      guard(() async => (await _api.getMe()).toDomain());

  @override
  Future<Result<Me>> updateName(String name) async {
    final r = await guard(
      () async => (await _api.patchMe(PatchMeRequest(name: name))).toDomain(),
    );
    if (r is Ok) notifyListeners();
    return r;
  }

  @override
  Future<Result<Me>> setNotifications(bool enabled) async {
    final r = await guard(
      () async =>
          (await _api.patchMe(PatchMeRequest(notificationsEnabled: enabled)))
              .toDomain(),
    );
    if (r is Ok) notifyListeners();
    return r;
  }

  @override
  Future<Result<void>> withdraw() async {
    final r = await guard(_api.deleteMe);
    if (r is Ok) notifyListeners();
    return r;
  }
}
