import 'dart:math';

/// 보내기·구매·선물 요청의 `Idempotency-Key` 값.
String newIdempotencyKey() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
