import 'package:shared_preferences/shared_preferences.dart';

/// 기기에 남기는 값 — 온보딩을 봤는지, 권한 안내를 했는지, 로그인 전에 연 링크.
abstract class AppPrefs {
  Future<bool> onboarded();
  Future<void> setOnboarded();

  Future<bool> permissionsAsked();
  Future<void> setPermissionsAsked();

  /// 로그인 전에 열어 둔 링크 토큰 (`/t/{token}`)
  Future<String?> pendingLink();
  Future<void> setPendingLink(String? token);

  /// 서랍 보기 (`list` · `shelf`). 사용자가 바꾼 적 없으면 null.
  Future<String?> shelfView();
  Future<void> setShelfView(String view);
}

class SharedAppPrefs implements AppPrefs {
  static const _onb = 'onboarded';
  static const _perm = 'permissionsAsked';
  static const _link = 'pendingLink';
  static const _shelfView = 'shelfView';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  @override
  Future<bool> onboarded() async => (await _p).getBool(_onb) ?? false;

  @override
  Future<void> setOnboarded() async => (await _p).setBool(_onb, true);

  @override
  Future<bool> permissionsAsked() async => (await _p).getBool(_perm) ?? false;

  @override
  Future<void> setPermissionsAsked() async => (await _p).setBool(_perm, true);

  @override
  Future<String?> pendingLink() async => (await _p).getString(_link);

  @override
  Future<void> setPendingLink(String? token) async {
    final p = await _p;
    token == null ? await p.remove(_link) : await p.setString(_link, token);
  }

  @override
  Future<String?> shelfView() async => (await _p).getString(_shelfView);

  @override
  Future<void> setShelfView(String view) async =>
      (await _p).setString(_shelfView, view);
}

/// 메모리 구현 (시험)
class MemoryAppPrefs implements AppPrefs {
  MemoryAppPrefs({this.onboardedValue = false, this.permissionsValue = false});

  bool onboardedValue;
  bool permissionsValue;
  String? link;

  @override
  Future<bool> onboarded() async => onboardedValue;

  @override
  Future<void> setOnboarded() async => onboardedValue = true;

  @override
  Future<bool> permissionsAsked() async => permissionsValue;

  @override
  Future<void> setPermissionsAsked() async => permissionsValue = true;

  @override
  Future<String?> pendingLink() async => link;

  @override
  Future<void> setPendingLink(String? token) async => link = token;

  String? shelfViewValue;

  @override
  Future<String?> shelfView() async => shelfViewValue;

  @override
  Future<void> setShelfView(String view) async => shelfViewValue = view;
}
