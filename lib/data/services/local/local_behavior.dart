/// 가짜 서버의 응답 시간과 실패 흉내 — 프로토타입 Tweaks의 `failMode`에 해당한다.
///
/// `--dart-define=FAIL_MODE=convertSlow` 처럼 골라 실행한다.
enum FailMode {
  none,
  convertSlow,
  convertFail,
  sendFail,
  offline;

  static FailMode parse(String value) =>
      values.firstWhere((m) => m.name == value, orElse: () => none);
}

class LocalBehavior {
  const LocalBehavior({
    this.failMode = FailMode.none,
    this.uploadDelay = const Duration(milliseconds: 300),
    this.convertDelay = const Duration(milliseconds: 900),
    this.convertSlowDelay = const Duration(milliseconds: 4500),
    this.convertFailDelay = const Duration(milliseconds: 1900),
    this.sendDelay = const Duration(milliseconds: 1200),
    this.sendFailDelay = const Duration(milliseconds: 1700),
  });

  factory LocalBehavior.fromEnvironment() => LocalBehavior(
    failMode: FailMode.parse(const String.fromEnvironment('FAIL_MODE')),
  );

  final FailMode failMode;
  final Duration uploadDelay;
  final Duration convertDelay;
  final Duration convertSlowDelay;
  final Duration convertFailDelay;
  final Duration sendDelay;
  final Duration sendFailDelay;

  bool get failsConvert =>
      failMode == FailMode.convertFail || failMode == FailMode.offline;
  bool get slowConvert => failMode == FailMode.convertSlow;
  bool get failsSend =>
      failMode == FailMode.sendFail || failMode == FailMode.offline;
}
