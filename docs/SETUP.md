# 실행 설정

## dart-define

| 이름 | 쓰임 | 비어 있으면 |
|---|---|---|
| `KAKAO_NATIVE_APP_KEY` | 카카오 로그인 SDK 초기화 | 카카오 버튼을 누르면 "카카오 앱 키가 설정되지 않았어요" 토스트 |
| `PUBLIC_HOST` | 테이프 링크 `https://<PUBLIC_HOST>/t/{token}`로 들어온 링크만 받는다 | 도메인을 가리지 않는다 |
| `ADMOB_REWARDED_ID` | 보상형 광고 단위 ID | 가짜 광고 (`POST /dev/credits`) |
| `IAP_ENABLED` | `true`면 실제 인앱 결제 | 가짜 결제 |
| `FAIL_MODE` | 가짜 서버 실패 흉내 (`lib/config/dependencies.dart` 참고) | 정상 |

```bash
flutter run \
  --dart-define=KAKAO_NATIVE_APP_KEY=abcd1234 \
  --dart-define=PUBLIC_HOST=cassette.app
```

## 네이티브 설정 (dart-define과 같은 값을 넣는다)

Android는 `android/app/build.gradle.kts`가 dart-define을 읽어 매니페스트에 넣는다. 따로 고칠 곳이 없다.

iOS는 Info.plist·entitlements가 dart-define을 읽지 못하므로 `ios/Flutter/Env.xcconfig`를 고친다.

```
KAKAO_NATIVE_APP_KEY = abcd1234
PUBLIC_HOST = cassette.app
```

| 항목 | iOS | Android |
|---|---|---|
| 테이프 링크 (유니버설/앱 링크) | `Runner.entitlements`의 `applinks:$(PUBLIC_HOST)` | `AndroidManifest.xml` `autoVerify` intent-filter, host `${publicHost}` |
| 웹 "앱에서 열기" `cassette://t/{token}` | `Info.plist` `CFBundleURLTypes`의 `cassette` | `AndroidManifest.xml` `cassette://t` intent-filter |
| 카카오 로그인 리다이렉트 | `Info.plist` `kakao$(KAKAO_NATIVE_APP_KEY)` 스킴 | `AuthCodeHandlerActivity`의 `kakao${kakaoNativeAppKey}://oauth` |

기본값 `cassette.example`은 자리표시자다. 실제 도메인을 쓰려면

1. 위처럼 `PUBLIC_HOST`(dart-define)와 `Env.xcconfig`의 `PUBLIC_HOST`를 같은 도메인으로 바꾼다.
2. 서버(`cassette-api`)가 그 도메인에서 `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`을 준다 (팀 ID·서명 인증서 SHA-256 필요).
3. Apple Developer에서 App ID에 Associated Domains·Sign in with Apple·Push Notifications를 켠다.

## Firebase (푸시)

설정 파일은 **커밋하지 않는다** (`.gitignore`에 있다). 각자 Firebase 콘솔에서 받아 넣는다.

- iOS: `ios/Runner/GoogleService-Info.plist` (Xcode에서 Runner 타깃에 추가)
- Android: `android/app/google-services.json`, 그리고 Google Services Gradle 플러그인(`com.google.gms.google-services`)을 `android/settings.gradle.kts`·`android/app/build.gradle.kts`에 추가
- APNs 인증 키를 Firebase 프로젝트에 올린다

파일이 없으면 `Firebase.initializeApp`이 실패하고 앱은 가짜 푸시(`LocalPushService`)로 돈다. 권한 요청·배너·알림 누르기는 가짜로도 시험할 수 있다.
