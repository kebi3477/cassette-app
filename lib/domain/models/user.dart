/// 나 — logic.js `myName`. 이 이름이 테이프의 "보낸 사람"에 들어간다.
class User {
  const User({required this.id, required this.name});

  final String id;

  /// 최대 8자
  final String name;

  static const int maxNameLength = 8;
}
