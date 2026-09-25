import 'package:flutter/foundation.dart';

/// 빌드할 때 `--dart-define`으로 넣는 값.
///
/// Xcode에서 빌드하거나 dart-define 없이 빌드해도 운영용으로 동작하도록 기본값을 둔다.
/// 공개값(카카오 네이티브 앱 키, 링크 도메인)은 항상 기본값이 있고, 서버 주소는
/// release 빌드에서만 운영 서버가 기본값이다(debug·테스트는 비워 두어 가짜 서버를 쓴다).
abstract final class Env {
  static const _prodApiBaseUrl = 'https://cassette.lab241.com/api';

  /// AdMob 보상형 광고 단위 ID. 비어 있으면 광고를 디자인의 광고 시트로 흉내 낸다.
  static const admobRewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');

  /// true면 App Store / Google Play 결제를 쓴다. 아니면 가짜 결제(1.4초 뒤 성공).
  static const iapEnabled = bool.fromEnvironment('IAP_ENABLED');

  /// 카카오 네이티브 앱 키. 앱에 들어가는 공개 키라 기본값을 둔다 (iOS는 Env.xcconfig에도 같은 값).
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: 'b53a18d3cc2caf80784d6ffd8bddb7c4',
  );

  /// 링크 도메인 (`https://<PUBLIC_HOST>/t/{token}`).
  static const publicHost = String.fromEnvironment(
    'PUBLIC_HOST',
    defaultValue: 'cassette.lab241.com',
  );

  /// 실제 서버 주소 (예: `http://localhost:3000/api`). 비어 있으면 서버 없이 도는 가짜 서버를 쓴다.
  /// release 빌드는 따로 넣지 않으면 운영 서버를 쓴다.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? _prodApiBaseUrl : '',
  );
}
