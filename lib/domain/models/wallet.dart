import 'tape_type.dart';

/// 크레딧과 보유 테이프 — logic.js `credits`, `owned`, `adsLeft`.
class Wallet {
  const Wallet({
    required this.credits,
    required this.owned,
    required this.adsLeft,
  });

  final int credits;

  /// 3분·5분 테이프 보유 수. 1분은 무제한이라 넣지 않는다.
  final Map<TapeType, int> owned;

  /// 오늘 남은 광고 보상 횟수
  final int adsLeft;

  /// [type] 테이프를 지금 녹음해서 보낼 수 있는지.
  bool canUse(TapeType type) => type.isUnlimited || ownedOf(type) > 0;

  int ownedOf(TapeType type) => owned[type] ?? 0;
}

/// 크레딧 내역 한 줄 — logic.js `ledger[]` (`{ date, why, amt }`).
class LedgerEntry {
  const LedgerEntry({
    required this.date,
    required this.reason,
    required this.amount,
  });

  final DateTime date;
  final String reason;

  /// 증감 (+/−)
  final int amount;
}

/// 크레딧 내역 한 페이지 (`GET /wallet/ledger?cursor=`)
class LedgerPage {
  const LedgerPage({required this.items, this.nextCursor});

  final List<LedgerEntry> items;
  final String? nextCursor;
}
