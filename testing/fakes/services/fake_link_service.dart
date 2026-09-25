import 'package:cassette_app/data/services/app_info_service.dart';
import 'package:cassette_app/data/services/link_service.dart';

class FakeLinkService implements LinkService {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class FakeAppInfoService implements AppInfoService {
  @override
  Future<String> version() async => '1.0.0';
}
