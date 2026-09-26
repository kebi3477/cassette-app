import 'json.dart';
import 'shelf_dto.dart';

/// 계약서 §2 Friend.
class FriendDto {
  const FriendDto({
    required this.userId,
    required this.name,
    this.nickname,
    required this.starred,
    this.lastAt,
  });

  final String userId;
  final String name;

  /// 내가 붙인 별명 (계약서 §2 별명). 화면에는 `nickname ?? name`.
  final String? nickname;
  final bool starred;
  final DateTime? lastAt;

  String get displayName => nickname ?? name;

  factory FriendDto.fromJson(Json j) => FriendDto(
    userId: j['userId'] as String,
    name: j['name'] as String,
    nickname: j['nickname'] as String?,
    starred: j['starred'] as bool,
    lastAt: parseDateOrNull(j['lastAt']),
  );

  Json toJson() => {
    'userId': userId,
    'name': name,
    'nickname': nickname,
    'starred': starred,
    'lastAt': lastAt == null ? null : dateToJson(lastAt!),
  };

  FriendDto copyWith({
    bool? starred,
    DateTime? lastAt,
    String? Function()? nickname,
  }) => FriendDto(
    userId: userId,
    name: name,
    nickname: nickname == null ? this.nickname : nickname(),
    starred: starred ?? this.starred,
    lastAt: lastAt ?? this.lastAt,
  );
}

/// `GET /friends/{userId}/tapes` — 친구 화면(`fvOn`).
class FriendTapesDto {
  const FriendTapesDto({
    required this.friend,
    required this.items,
    required this.unopenedCount,
  });

  final FriendDto friend;

  /// 뜯은 테이프만. 각 항목에 `groupName`이 붙는다.
  final List<ShelfItemDto> items;
  final int unopenedCount;

  factory FriendTapesDto.fromJson(Json j) => FriendTapesDto(
    friend: FriendDto.fromJson(j['friend'] as Json),
    items: parseList(j['items'], ShelfItemDto.fromJson),
    unopenedCount: j['unopenedCount'] as int,
  );

  Json toJson() => {
    'friend': friend.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'unopenedCount': unopenedCount,
  };
}

/// 계약서 §2 BlockedUser
class BlockedUserDto {
  const BlockedUserDto({
    required this.userId,
    required this.name,
    this.nickname,
    required this.blockedAt,
  });

  final String userId;
  final String name;

  /// 차단할 때 붙어 있던 별명
  final String? nickname;
  final DateTime blockedAt;

  String get displayName => nickname ?? name;

  factory BlockedUserDto.fromJson(Json j) => BlockedUserDto(
    userId: j['userId'] as String,
    name: j['name'] as String,
    nickname: j['nickname'] as String?,
    blockedAt: parseDate(j['blockedAt']),
  );

  Json toJson() => {
    'userId': userId,
    'name': name,
    'nickname': nickname,
    'blockedAt': dateToJson(blockedAt),
  };
}
