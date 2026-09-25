/// 빌드할 때 `--dart-define`으로 넣는 값.
abstract final class Env {
  /// AdMob 보상형 광고 단위 ID. 비어 있으면 광고를 디자인의 광고 시트로 흉내 낸다.
  static const admobRewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');

  /// true면 App Store / Google Play 결제를 쓴다. 아니면 가짜 결제(1.4초 뒤 성공).
  static const iapEnabled = bool.fromEnvironment('IAP_ENABLED');

  /// 카카오 네이티브 앱 키. 비어 있으면 카카오 버튼이 토스트로 안내한다.
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );

  /// 링크 도메인 (`https://<PUBLIC_HOST>/t/{token}`). 비어 있으면 도메인을 가리지 않는다.
  static const publicHost = String.fromEnvironment('PUBLIC_HOST');
}
