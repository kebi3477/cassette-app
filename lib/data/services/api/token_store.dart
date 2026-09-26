import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// access·refresh 토큰 쌍
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// 토큰 저장소 (Keychain / Keystore). 실제 구현은 [SecureTokenStore].
abstract class TokenStore {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _access = 'tapeletter.accessToken';
  static const _refresh = 'tapeletter.refreshToken';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<AuthTokens?> read() async {
    final a = await _storage.read(key: _access);
    final r = await _storage.read(key: _refresh);
    if (a == null || r == null) return null;
    return AuthTokens(access: a, refresh: r);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _access, value: tokens.access);
    await _storage.write(key: _refresh, value: tokens.refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// 메모리 토큰 저장소 (시험, 로컬 실행)
class MemoryTokenStore implements TokenStore {
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens t) async => tokens = t;

  @override
  Future<void> clear() async => tokens = null;
}
