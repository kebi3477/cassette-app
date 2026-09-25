import 'json.dart';

/// `GET /users/me` — 계약서 §2 Me.
class MeDto {
  const MeDto({
    required this.id,
    required this.name,
    required this.credits,
    required this.drawer,
    required this.tapes,
    required this.stats,
    required this.providers,
    required this.notificationsEnabled,
    required this.createdAt,
  });

  final String id;

  /// 가입 직후 null
  final String? name;
  final int credits;
  final DrawerDto drawer;
  final List<TapeStockDto> tapes;
  final StatsDto stats;
  final List<String> providers;
  final bool notificationsEnabled;
  final DateTime createdAt;

  factory MeDto.fromJson(Json j) => MeDto(
    id: j['id'] as String,
    name: j['name'] as String?,
    credits: j['credits'] as int,
    drawer: DrawerDto.fromJson(j['drawer'] as Json),
    tapes: parseList(j['tapes'], TapeStockDto.fromJson),
    stats: StatsDto.fromJson(j['stats'] as Json),
    providers: (j['providers'] as List).cast<String>(),
    notificationsEnabled: j['notificationsEnabled'] as bool,
    createdAt: parseDate(j['createdAt']),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'credits': credits,
    'drawer': drawer.toJson(),
    'tapes': tapes.map((t) => t.toJson()).toList(),
    'stats': stats.toJson(),
    'providers': providers,
    'notificationsEnabled': notificationsEnabled,
    'createdAt': dateToJson(createdAt),
  };
}

/// `drawer { stored, cap, full, unopenedCount }`
class DrawerDto {
  const DrawerDto({
    required this.stored,
    required this.cap,
    required this.full,
    this.unopenedCount = 0,
  });

  final int stored;
  final int cap;
  final bool full;

  /// 안 뜯은 소포 수 (탭바 서랍 레드 점). 관제자가 계약서에 추가를 요청한 필드.
  final int unopenedCount;

  factory DrawerDto.fromJson(Json j) => DrawerDto(
    stored: j['stored'] as int,
    cap: j['cap'] as int,
    full: j['full'] as bool,
    unopenedCount: (j['unopenedCount'] as int?) ?? 0,
  );

  Json toJson() => {
    'stored': stored,
    'cap': cap,
    'full': full,
    'unopenedCount': unopenedCount,
  };
}

/// `tapes[] { tapeType, qty }` — 1분은 `qty: null`(무제한)
class TapeStockDto {
  const TapeStockDto({required this.tapeType, required this.qty});

  final int tapeType;
  final int? qty;

  factory TapeStockDto.fromJson(Json j) =>
      TapeStockDto(tapeType: j['tapeType'] as int, qty: j['qty'] as int?);

  Json toJson() => {'tapeType': tapeType, 'qty': qty};
}

class StatsDto {
  const StatsDto({
    required this.receivedCount,
    required this.sentCount,
    required this.friendCount,
  });

  final int receivedCount;
  final int sentCount;
  final int friendCount;

  factory StatsDto.fromJson(Json j) => StatsDto(
    receivedCount: j['receivedCount'] as int,
    sentCount: j['sentCount'] as int,
    friendCount: j['friendCount'] as int,
  );

  Json toJson() => {
    'receivedCount': receivedCount,
    'sentCount': sentCount,
    'friendCount': friendCount,
  };
}

/// `PATCH /users/me` 요청 — 바꿀 필드만.
class PatchMeRequest {
  const PatchMeRequest({this.name, this.notificationsEnabled});

  final String? name;
  final bool? notificationsEnabled;

  Json toJson() => {
    'name': ?name,
    'notificationsEnabled': ?notificationsEnabled,
  };
}
