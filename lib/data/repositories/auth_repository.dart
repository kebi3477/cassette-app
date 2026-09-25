/// 로그인 상태. 로그인·토큰은 4단계에서 붙인다 (`/auth/*`).
abstract class AuthRepository {
  /// 로그아웃 (`POST /auth/logout`). 지금은 토큰이 없어 기기 상태만 지운다.
  Future<void> logout();
}
