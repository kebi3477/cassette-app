import 'tape_type.dart';

/// 내 정보 — 계약서 Me (`GET /users/me`).
class Me {
  const Me({
    required this.id,
    required this.name,
    required this.credits,
    required this.owned,
    required this.drawer,
    required this.receivedCount,
    required this.sentCount,
    required this.friendCount,
  });

  final String id;

  /// 가입 직후 빈 문자열 (이름 정하기 화면)
  final String name;
  final int credits;

  /// 3분·5분 보유 수. 1분은 무제한이라 넣지 않는다.
  final Map<TapeType, int> owned;
  final DrawerSummary drawer;
  final int receivedCount;
  final int sentCount;
  final int friendCount;
}

/// `drawer { stored, cap, full, unopenedCount }`
class DrawerSummary {
  const DrawerSummary({
    required this.stored,
    required this.cap,
    required this.full,
    required this.unopenedCount,
  });

  final int stored;
  final int cap;
  final bool full;
  final int unopenedCount;
}
