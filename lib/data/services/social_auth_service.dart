import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 소셜 로그인 결과
sealed class SocialLogin {
  const SocialLogin();
}

/// 카카오 액세스 토큰 → `POST /auth/kakao`
class KakaoLogin extends SocialLogin {
  const KakaoLogin(this.accessToken);

  final String accessToken;
}

/// Apple → `POST /auth/apple` (`authorizationCode`도 보낸다)
class AppleLogin extends SocialLogin {
  const AppleLogin({
    required this.identityToken,
    required this.authorizationCode,
    this.nonce,
    this.givenName,
  });

  final String identityToken;
  final String authorizationCode;
  final String? nonce;

  /// 첫 로그인 때만 온다 — 이름 정하기 화면에 미리 채운다.
  final String? givenName;
}

/// 사용자가 창을 닫았다
class SocialCanceled extends SocialLogin {
  const SocialCanceled();
}

/// 설정이 없어 쓸 수 없다 (예: 카카오 네이티브 앱 키 없음)
class SocialUnavailable extends SocialLogin {
  const SocialUnavailable(this.message);

  final String message;
}

class SocialFailed extends SocialLogin {
  const SocialFailed([this.message]);

  final String? message;
}

/// 카카오·Apple 로그인 SDK.
abstract class SocialAuthService {
  Future<SocialLogin> kakao();

  Future<SocialLogin> apple();
}

/// `kakao_flutter_sdk_user` + `sign_in_with_apple`.
class PlatformSocialAuthService implements SocialAuthService {
  PlatformSocialAuthService({required this.kakaoNativeAppKey});

  final String kakaoNativeAppKey;
  bool _kakaoReady = false;

  static const kakaoKeyMissing = '카카오 앱 키가 설정되지 않았어요';

  @override
  Future<SocialLogin> kakao() async {
    if (kakaoNativeAppKey.isEmpty) {
      return const SocialUnavailable(kakaoKeyMissing);
    }
    try {
      if (!_kakaoReady) {
        await KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
        _kakaoReady = true;
      }
      final token = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      return KakaoLogin(token.accessToken);
    } on KakaoAuthException catch (e) {
      return e.error == AuthErrorCause.accessDenied
          ? const SocialCanceled()
          : SocialFailed(e.message);
    } on KakaoClientException catch (e) {
      return e.reason == ClientErrorCause.cancelled
          ? const SocialCanceled()
          : SocialFailed(e.msg);
    } catch (e) {
      return SocialFailed('$e');
    }
  }

  @override
  Future<SocialLogin> apple() async {
    final nonce = _nonce();
    try {
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      final idToken = c.identityToken;
      if (idToken == null) return const SocialFailed();
      return AppleLogin(
        identityToken: idToken,
        authorizationCode: c.authorizationCode,
        nonce: nonce,
        givenName: c.givenName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      return e.code == AuthorizationErrorCode.canceled
          ? const SocialCanceled()
          : SocialFailed(e.message);
    } catch (e) {
      return SocialFailed('$e');
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
