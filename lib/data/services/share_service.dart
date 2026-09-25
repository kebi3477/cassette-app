import 'package:share_plus/share_plus.dart';

/// 시스템 공유 시트. 카카오톡·문자 전용 연동은 다음 단계에서 붙인다.
abstract class ShareService {
  /// 공유했으면 true, 사용자가 닫았으면 false.
  Future<bool> shareText(String text);
}

class SystemShareService implements ShareService {
  @override
  Future<bool> shareText(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    return result.status != ShareResultStatus.dismissed;
  }
}
