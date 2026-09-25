import 'package:app_links/app_links.dart';

/// 유니버설 링크 / 앱 링크 (`https://<도메인>/t/{token}`)
abstract class DeepLinkService {
  Future<Uri?> initialLink();

  Stream<Uri> get links;
}

class AppLinksDeepLinkService implements DeepLinkService {
  final AppLinks _links = AppLinks();

  @override
  Future<Uri?> initialLink() => _links.getInitialLink();

  @override
  Stream<Uri> get links => _links.uriLinkStream;
}
