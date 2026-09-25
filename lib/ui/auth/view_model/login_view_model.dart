import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../core/ui/toast.dart';

enum LoginProvider { kakao, apple }

/// 로그인 (`auLogin`) — 카카오·Apple, 누르면 "연결 중…" (최소 0.7초).
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this._auth, required this._toast});

  /// `later('auth', 700)`
  static const connectingTime = Duration(milliseconds: 700);

  final AuthRepository _auth;
  final ToastController _toast;
  LoginProvider? _busy;

  /// "연결 중…"인 버튼
  LoginProvider? get busy => _busy;

  Future<void> signIn(LoginProvider p) =>
      _run(p, p == LoginProvider.kakao ? _auth.signInKakao : _auth.signInApple);

  /// 개발 로그인 (숨은 진입점)
  Future<void> signInDev() => _run(
    LoginProvider.kakao,
    () => _auth.signInDev(key: 'minkyung', name: '민경'),
  );

  Future<void> _run(
    LoginProvider p,
    Future<SignInResult> Function() call,
  ) async {
    if (_busy != null) return;
    _busy = p;
    notifyListeners();
    final results = await Future.wait<Object?>([
      call(),
      Future<void>.delayed(connectingTime),
    ]);
    _busy = null;
    notifyListeners();
    final r = results.first! as SignInResult;
    if (r is SignInFailed) _toast.show(r.message);
  }
}
