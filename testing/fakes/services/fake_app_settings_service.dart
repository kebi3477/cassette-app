import 'package:tapeletter_app/data/services/app_settings_service.dart';

class FakeAppSettingsService implements AppSettingsService {
  int opened = 0;

  @override
  Future<void> openAppSettings() async => opened++;
}
