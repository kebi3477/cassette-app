import 'package:url_launcher/url_launcher.dart';

/// 약관·개인정보 처리방침·문의하기 링크 열기.
abstract class LinkService {
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkService implements LinkService {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
