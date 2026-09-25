import '../../utils/result.dart';
import '../model/api_error.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';

/// 강제 업데이트 안내에 필요한 값 (`GET /app-version`)
class UpdateInfo {
  const UpdateInfo({required this.required, required this.storeUrl});

  final bool required;
  final Uri storeUrl;
}

/// 앱 버전 확인과 서버 상태 (`/app-version`, `/health`)
class AppRepository {
  AppRepository(this._api);

  final ApiClient _api;

  Future<Result<UpdateInfo>> checkVersion({
    required String platform,
    required String version,
  }) => guard(() async {
    final v = await _api.getAppVersion(platform: platform, version: version);
    return UpdateInfo(
      required: v.updateRequired ?? false,
      storeUrl: Uri.parse(v.storeUrl),
    );
  });

  /// 서버 오류 화면의 다시 시도
  Future<bool> healthy() async {
    try {
      await _api.health();
      return true;
    } on ApiException catch (_) {
      return false;
    }
  }
}
