import 'json.dart';
import 'shelf_dto.dart';

/// 계약서 §2 Friend.
class FriendDto {
  const FriendDto({
    required this.userId,
    required this.name,
    required this.starred,
    this.lastAt,
  });

  final String userId;
  final String name;
  final bool starred;
  final DateTime? lastAt;

  factory FriendDto.fromJson(Json j) => FriendDto(
    userId: j['userId'] as String,
    name: j['name'] as String,
    starred: j['starred'] as bool,
    lastAt: parseDateOrNull(j['lastAt']),
  );

  Json toJson() => {
    'userId': userId,
    'name': name,
    'starred': starred,
    'lastAt': lastAt == null ? null : dateToJson(lastAt!),
  };

  FriendDto copyWith({bool? starred, DateTime? lastAt}) => FriendDto(
    userId: userId,
    name: name,
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
