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
    final r = results.first! as SignInResult;
    if (r is SignInFailed) _toast.show(r.message);
    // 로그인에 성공하면 관문이 다음 화면으로 넘기면서 이 ViewModel을 버린다.
    if (_disposed) return;
    _busy = null;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
