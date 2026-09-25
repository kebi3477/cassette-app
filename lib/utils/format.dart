/// logic.js `fmt`: 초 → `m:ss`.
String formatClock(num seconds) {
  final s = seconds.floor();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// 날짜 → `MM.DD` (프로토타입 표기).
String formatMonthDay(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
