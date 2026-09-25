import 'auth_repository.dart';

/// 로그인 전 단계의 자리. 로그아웃해도 지울 토큰이 없다.
class AuthRepositoryLocal implements AuthRepository {
  bool loggedIn = true;

  @override
  Future<void> logout() async => loggedIn = false;
}
