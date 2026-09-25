/// 테이프 종류 — logic.js `T`의 키(1·3·5)와 같다.
enum TapeType {
  one(1),
  three(3),
  five(5);

  const TapeType(this.minutes);

  /// 테이프 길이(분). API에서도 이 숫자로 주고받는다.
  final int minutes;

  /// 녹음 한도(초)
  int get seconds => minutes * 60;

  Duration get maxDuration => Duration(seconds: seconds);

  /// 1분 테이프는 무제한 무료이고 보유 수를 세지 않는다.
  bool get isUnlimited => this == TapeType.one;

  static TapeType fromMinutes(int minutes) =>
      values.firstWhere((t) => t.minutes == minutes);
}
