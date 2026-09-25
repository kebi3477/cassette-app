/// 가짜 서버의 응답 시간과 실패 흉내 — 프로토타입 Tweaks의 `failMode`에 해당한다.
///
/// `--dart-define=FAIL_MODE=convertSlow` 처럼 골라 실행한다.
enum FailMode {
  none,
  convertSlow,
  convertFail,
  sendFail,
  loadFail,
  payFail,
  adFail,
  serverError,
  forceUpdate,
  linkTaken,
  linkExpired,
  linkOwn,
  rejoinRestricted,
  offline;

  static FailMode parse(String value) =>
      values.firstWhere((m) => m.name == value, orElse: () => none);
}

class LocalBehavior {
  const LocalBehavior({
    this.failMode = FailMode.none,
    this.latency = const Duration(milliseconds: 120),
    this.convertDelay = const Duration(milliseconds: 700),
    this.convertSlowDelay = const Duration(milliseconds: 4500),
    this.convertFailDelay = const Duration(milliseconds: 1200),
    this.sendDelay = const Duration(milliseconds: 1200),
    this.sendFailDelay = const Duration(milliseconds: 1700),
    this.requireAuth = false,
  });

  factory LocalBehavior.fromEnvironment() => LocalBehavior(
    failMode: FailMode.parse(const String.fromEnvironment('FAIL_MODE')),
    requireAuth: true,
  );

  /// 시험용: 지연 없음
  static const instant = LocalBehavior(
    latency: Duration.zero,
    convertDelay: Duration.zero,
    convertSlowDelay: Duration.zero,
    convertFailDelay: Duration.zero,
    sendDelay: Duration.zero,
    sendFailDelay: Duration.zero,
  );

  /// 시험용: 실패 흉내·인증만 바꾼 복사본
  LocalBehavior copyWith({FailMode? failMode, bool? requireAuth}) =>
      LocalBehavior(
        failMode: failMode ?? this.failMode,
        latency: latency,
        convertDelay: convertDelay,
        convertSlowDelay: convertSlowDelay,
        convertFailDelay: convertFailDelay,
        sendDelay: sendDelay,
        sendFailDelay: sendFailDelay,
        requireAuth: requireAuth ?? this.requireAuth,
      );

  final FailMode failMode;

  /// 보호된 API에 유효한 access token을 요구한다 (앱에서 켠다. 시험은 기본 끔)
  final bool requireAuth;

  /// 모든 요청의 기본 응답 시간
  final Duration latency;

  /// complete 뒤 변환이 끝나기까지
  final Duration convertDelay;
  final Duration convertSlowDelay;
  final Duration convertFailDelay;
  final Duration sendDelay;
  final Duration sendFailDelay;

  bool get offline => failMode == FailMode.offline;
  bool get failsConvert => failMode == FailMode.convertFail || offline;
  bool get slowConvert => failMode == FailMode.convertSlow;
  bool get failsSend => failMode == FailMode.sendFail || offline;
  bool get failsAudio => failMode == FailMode.loadFail || offline;
  bool get failsPay => failMode == FailMode.payFail || offline;
  bool get failsAd => failMode == FailMode.adFail || offline;
  bool get serverDown => failMode == FailMode.serverError;
  bool get forcesUpdate => failMode == FailMode.forceUpdate;
}
