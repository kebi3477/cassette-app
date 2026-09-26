import 'package:tapeletter_app/data/services/share_service.dart';

class FakeShareService implements ShareService {
  FakeShareService({this.result = true});

  /// 공유 시트에서 공유했는지(true) 닫았는지(false)
  bool result;
  final List<String> shared = [];

  @override
  Future<bool> shareText(String text) async {
    shared.add(text);
    return result;
  }
}
