import 'json.dart';

/// 목록 응답 `{ items, nextCursor }` (계약서 §1 목록).
class PageDto<T> {
  const PageDto({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  factory PageDto.fromJson(Json json, T Function(Json) item) => PageDto(
    items: parseList(json['items'], item),
    nextCursor: json['nextCursor'] as String?,
  );

  Json toJson(Json Function(T) item) => {
    'items': items.map(item).toList(),
    'nextCursor': nextCursor,
  };
}
