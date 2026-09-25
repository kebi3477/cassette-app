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

## 실제 서버로 실행하기

`--dart-define=API_BASE_URL=`이 있으면 앱이 실제 서버(`HttpApiClient`, dio)에 붙고, 없으면 서버 없이 도는 가짜 서버(`LocalApiClient`)를 쓴다. 실제 서버일 때 토큰은 Keychain / Keystore(`flutter_secure_storage`)에 저장된다.

1. 서버 실행 (`../cassette-api`, 계약서 `docs/api.md` "0. 로컬 개발 서버에 붙기")
   ```bash
   cd ../cassette-api && npm run start:dev      # Postgres·Redis가 떠 있어야 한다
   ```
2. 앱 실행
   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
   ```
3. 로그인 화면에서 **앱 아이콘을 길게 누르면** 개발 로그인(`POST /auth/dev`, key `minkyung`, 이름 "민경")이다. 개발 빌드에서만 된다.
   프로토타입 데이터가 필요하면 먼저 시드를 만든다.
   ```bash
   T=$(curl -s -X POST localhost:3000/api/auth/dev -H 'content-type: application/json' \
     -d '{"key":"minkyung","name":"민경"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["accessToken"])')
   curl -s -X POST localhost:3000/api/dev/seed -H "authorization: Bearer $T"
   ```

### 기기별 주소

| 기기 | `API_BASE_URL` | API `.env`의 `PUBLIC_BASE_URL` |
|---|---|---|
| iOS 시뮬레이터 | `http://localhost:3000/api` | `http://localhost:3000` |
| Android 에뮬레이터 | `http://10.0.2.2:3000/api` | `http://10.0.2.2:3000` |
| 실기기 (같은 와이파이) | `http://<맥 IP>:3000/api` (예: `http://192.168.0.10:3000/api`) | `http://<맥 IP>:3000` |

- 업로드·재생 URL과 링크 주소는 서버가 `PUBLIC_BASE_URL`로 만든다. **기기에서 닿지 않는 주소면 녹음 업로드와 재생이 실패한다.** 바꾼 뒤 서버를 다시 켠다.
- 맥 IP: `ipconfig getifaddr en0`
- iOS는 `Info.plist`의 `NSAllowsLocalNetworking`으로 로컬 주소(`localhost`, `192.168.x.x`)에만 http를 허용한다. 운영 주소는 https여야 한다.
- Android는 **debug·profile 빌드에서만** http를 허용한다. 빌드할 때 `network_security_config.xml`을 만들어(`android/app/build.gradle.kts`) `src/debug`·`src/profile` 매니페스트로 붙인다. 허용하는 곳은 `localhost`, `127.0.0.1`, `10.0.2.2`(에뮬레이터), 그리고 `API_BASE_URL`의 호스트가 사설 IP(`10.x`, `172.16~31.x`, `192.168.x`)면 그 주소다. Android 설정은 IP 대역을 쓸 수 없어서 dart-define의 맥 IP를 그대로 넣는다. release 빌드에는 들어가지 않는다.
  ```bash
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api     # 에뮬레이터
  flutter run -d <기기> --dart-define=API_BASE_URL=http://192.168.0.10:3000/api        # 실기기 (맥 IP)
  ```
  맥 IP가 바뀌면 다시 빌드한다 (hot reload로는 바뀌지 않는다).

### 받은 테이프 캐시

재생 URL은 10분짜리라, 한 번 받은 파일은 **delivery id**를 이름으로 앱 캐시 폴더(`<cache>/tapes/`)에 두고 다음부터는 그 파일을 재생한다. 테이프를 지우면 그 파일을, 로그아웃·탈퇴하면 전부 지운다.

### 서버에 붙는 시험

```bash
# 계약서의 흐름을 실제 HTTP로 (기본 flutter test에서는 건너뛴다)
flutter test --tags server --dart-define=API_BASE_URL=http://localhost:3000/api

# 시뮬레이터에서 화면 흐름 (개발 로그인 → 녹음 → 서랍 → 재생 → 상점 → 마이) + 캡처
tool/sim_flow.sh <시뮬레이터 UDID> http://localhost:3000/api   # build/screenshots/server_*.png
tool/sim_flow.sh <시뮬레이터 UDID>                             # 가짜 서버: local_*.png
```
- 개발 로그인은 IP당 1분 20번이라(`429 RATE_LIMITED`) 서버 시험을 연달아 돌리면 잠시 기다린다.
- 시뮬레이터 흐름은 마이크·알림 안내를 건너뛴다(`flutter drive`가 앱을 다시 설치하면서 마이크 권한이 초기화돼 OS 권한 창이 화면을 가린다). 안내 화면은 위젯 시험이 확인한다.
