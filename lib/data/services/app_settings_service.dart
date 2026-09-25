import 'package:app_settings/app_settings.dart';

/// 앱 설정 화면 열기 (마이크 권한을 다시 켤 때).
abstract class AppSettingsService {
  Future<void> openAppSettings();
}

class SystemAppSettingsService implements AppSettingsService {
  @override
  Future<void> openAppSettings() => AppSettings.openAppSettings();
}
