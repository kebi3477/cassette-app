import 'package:package_info_plus/package_info_plus.dart';

/// 앱 버전 (설정 > 앱 버전)
abstract class AppInfoService {
  Future<String> version();
}

class PackageAppInfoService implements AppInfoService {
  @override
  Future<String> version() async => (await PackageInfo.fromPlatform()).version;
}
