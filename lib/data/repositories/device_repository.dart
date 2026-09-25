import '../../utils/result.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';

/// 푸시 기기 토큰 등록 (`/notifications/devices`)
class DeviceRepository {
  DeviceRepository(this._api);

  final ApiClient _api;
  String? _registered;

  /// 로그인 후, 토큰이 바뀔 때마다. 같은 토큰은 한 번만.
  Future<Result<void>> register(String token, String platform) async {
    if (_registered == token) return const Result.ok(null);
    final r = await guard(
      () => _api.registerDevice(token: token, platform: platform),
    );
    if (r is Ok) _registered = token;
    return r;
  }

  void forget() => _registered = null;
}
