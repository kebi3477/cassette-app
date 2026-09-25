import 'package:flutter/foundation.dart';

import '../data/repositories/app_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/app_info_service.dart';
import '../data/services/app_prefs.dart';
import '../utils/result.dart';
import 'routes.dart';

/// 처음 실행부터 앱 본문까지의 관문 — 스플래시, 강제 업데이트, 온보딩, 로그인, 이름, 권한 안내.
///
/// 라우터의 `refreshListenable`이고, [redirect]가 갈 곳을 정한다.
class AppFlow extends ChangeNotifier {
  AppFlow({
    required this._auth,
    required this._prefs,
    required this._app,
    required this._appInfo,
    required this.platform,
    this.onSignedIn,
  }) {
    _auth.addListener(_onAuth);
  }

  /// 스플래시 1.4초 (`later('splash', 1400)`)
  static const splashTime = Duration(milliseconds: 1400);

  final AuthRepository _auth;
  final AppPrefs _prefs;
  final AppRepository _app;
  final AppInfoService _appInfo;

  /// `ios` · `android` (`GET /app-version?platform=`)
  final String platform;

  /// 로그인이 끝났을 때 — 이전 사용자의 화면 데이터를 다시 불러오게 한다.
  final VoidCallback? onSignedIn;

  bool _splashDone = false;
  bool _booted = false;
  bool _onboarded = false;
  bool _permissionsAsked = false;
  bool _updateRequired = false;
  Uri? _storeUrl;
  AuthStatus _lastStatus = AuthStatus.unknown;

  bool get ready => _splashDone && _booted;
  bool get updateRequired => _updateRequired;
  Uri? get storeUrl => _storeUrl;
  bool get onboarded => _onboarded;
  bool get permissionsAsked => _permissionsAsked;
  AuthStatus get authStatus => _auth.status;

  /// 링크·푸시를 처리해도 되는 상태 (앱 본문)
  bool get inApp =>
      ready &&
      !_updateRequired &&
      _onboarded &&
      _auth.status == AuthStatus.signedIn &&
      _permissionsAsked;

  /// 앱 시작: 버전 확인, 기기 값, 저장된 로그인 복원
  Future<void> boot() async {
    await Future.wait([_checkVersion(), _loadPrefs(), _auth.restore()]);
    _booted = true;
    notifyListeners();
  }

  Future<void> _checkVersion() async {
    try {
      final version = await _appInfo.version();
      final r = await _app.checkVersion(platform: platform, version: version);
      if (r case Ok(:final value)) {
        _updateRequired = value.required;
        _storeUrl = value.storeUrl;
      }
    } catch (_) {
      // 버전을 모르면 막지 않는다.
    }
  }

  Future<void> _loadPrefs() async {
    _onboarded = await _prefs.onboarded();
    _permissionsAsked = await _prefs.permissionsAsked();
  }

  void finishSplash() {
    if (_splashDone) return;
    _splashDone = true;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    await _prefs.setOnboarded();
    _onboarded = true;
    notifyListeners();
  }

  Future<void> finishPermissions() async {
    await _prefs.setPermissionsAsked();
    _permissionsAsked = true;
    notifyListeners();
  }

  void _onAuth() {
    final s = _auth.status;
    if (s == AuthStatus.signedIn && _lastStatus != AuthStatus.signedIn) {
      onSignedIn?.call();
    }
    _lastStatus = s;
    notifyListeners();
  }

  /// 관문을 거치느라 못 간 앱 안 주소 — 관문이 끝나면 그리로 간다.
  String? _resume;

  String? redirect(String location) {
    final to = decide(
      ready: ready,
      updateRequired: _updateRequired,
      onboarded: _onboarded,
      auth: _auth.status,
      permissionsAsked: _permissionsAsked,
      location: location,
      home: _resume ?? Routes.record,
    );
    if (to != null && Routes.isGate(to) && !Routes.isGate(location)) {
      _resume = location;
    } else if (to != null && !Routes.isGate(to)) {
      _resume = null;
    }
    return to;
  }

  /// 관문 규칙. null이면 그대로 둔다.
  @visibleForTesting
  static String? decide({
    required bool ready,
    required bool updateRequired,
    required bool onboarded,
    required AuthStatus auth,
    required bool permissionsAsked,
    required String location,
    String home = Routes.record,
  }) {
    String? go(String to) => location == to ? null : to;
    if (updateRequired && ready) return go(Routes.update);
    if (!ready) return go(Routes.splash);
    if (!onboarded) return go(Routes.onboarding);
    switch (auth) {
      case AuthStatus.unknown:
      case AuthStatus.signedOut:
        return go(Routes.login);
      case AuthStatus.needsName:
        return go(Routes.name);
      case AuthStatus.signedIn:
        if (!permissionsAsked) {
          return location.startsWith(Routes.permissions)
              ? null
              : Routes.permissionsMic;
        }
        return Routes.isGate(location) ? home : null;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }
}
