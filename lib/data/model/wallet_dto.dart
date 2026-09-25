import 'json.dart';

/// `GET /wallet`
class WalletDto {
  const WalletDto({required this.credits, required this.ads});

  final int credits;
  final AdsDto ads;

  factory WalletDto.fromJson(Json j) => WalletDto(
    credits: j['credits'] as int,
    ads: AdsDto.fromJson(j['ads'] as Json),
  );

  Json toJson() => {'credits': credits, 'ads': ads.toJson()};
}

class AdsDto {
  const AdsDto({
    required this.rewardPerView,
    required this.dailyLimit,
    required this.remainingToday,
  });

  final int rewardPerView;
  final int dailyLimit;
  final int remainingToday;

  factory AdsDto.fromJson(Json j) => AdsDto(
    rewardPerView: j['rewardPerView'] as int,
    dailyLimit: j['dailyLimit'] as int,
    remainingToday: j['remainingToday'] as int,
  );

  Json toJson() => {
    'rewardPerView': rewardPerView,
    'dailyLimit': dailyLimit,
    'remainingToday': remainingToday,
  };
}

/// 계약서 §2 LedgerEntry
class LedgerEntryDto {
  const LedgerEntryDto({
    required this.id,
    required this.delta,
    required this.reason,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final int delta;
  final String reason;
  final String kind;
  final DateTime createdAt;

  factory LedgerEntryDto.fromJson(Json j) => LedgerEntryDto(
    id: j['id'] as String,
    delta: j['delta'] as int,
    reason: j['reason'] as String,
    kind: j['kind'] as String,
    createdAt: parseDate(j['createdAt']),
  );

  Json toJson() => {
    'id': id,
    'delta': delta,
    'reason': reason,
    'kind': kind,
    'createdAt': dateToJson(createdAt),
  };
}
