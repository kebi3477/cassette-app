/// 테이프 종류 — API `tapeType` 코드는 길이(초)다: `15` · `60` · `180`.
/// 디자인 `T` 표의 옛 1·3·5분 자리를 그대로 옮겼다 (15초 = 옛 1분 모양, 1분 = 옛 3분, 3분 = 옛 5분).
enum TapeType {
  s15(15, '15초'),
  m1(60, '1분'),
  m3(180, '3분');

  const TapeType(this.code, this.label);

  /// API 코드이자 녹음 한도(초)
  final int code;

  /// 화면 표기 (`15초`)
  final String label;

  /// 녹음 한도(초)
  int get seconds => code;

  Duration get maxDuration => Duration(seconds: seconds);

  /// 15초 테이프는 무제한 무료이고 보유 수를 세지 않는다.
  bool get isUnlimited => this == TapeType.s15;

  static TapeType fromCode(int code) =>
      values.firstWhere((t) => t.code == code);
}
