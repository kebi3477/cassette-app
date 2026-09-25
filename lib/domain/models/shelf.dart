import 'tape_item.dart';

/// 사용자 칸 — logic.js `Group`.
class ShelfGroup {
  const ShelfGroup({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<TapeItem> items;

  ShelfGroup copyWith({String? name, List<TapeItem>? items}) =>
      ShelfGroup(id: id, name: name ?? this.name, items: items ?? this.items);
}

/// 서랍 전체 — "분류 안 함"(`unsorted`) + 사용자 칸 + 보관 한도.
class Shelf {
  const Shelf({
    required this.unsorted,
    required this.groups,
    required this.cap,
  });

  static const empty = Shelf(unsorted: [], groups: [], cap: 12);

  /// 분류 안 함. 새로 받은 테이프가 여기로 들어온다.
  final List<TapeItem> unsorted;
  final List<ShelfGroup> groups;

  /// 보관 한도 (처음 12)
  final int cap;

  /// 보관량 = 모든 칸의 테이프 수 + 분류 안 함의 테이프 수
  int get stored =>
      groups.fold<int>(0, (a, g) => a + g.items.length) + unsorted.length;

  bool get full => stored >= cap;

  bool get isEmpty => unsorted.isEmpty && groups.isEmpty;

  int get unopenedCount => unsorted.where((x) => !x.opened).length;

  bool get hasNew => unopenedCount > 0;

  ShelfGroup? group(String id) => groups.where((g) => g.id == id).firstOrNull;

  /// [groupId]가 null이면 분류 안 함.
  List<TapeItem> itemsOf(String? groupId) =>
      groupId == null ? unsorted : (group(groupId)?.items ?? const []);

  TapeItem? find(String id) {
    for (final x in unsorted) {
      if (x.id == id) return x;
    }
    for (final g in groups) {
      for (final x in g.items) {
        if (x.id == id) return x;
      }
    }
    return null;
  }

  Shelf copyWith({List<TapeItem>? unsorted, List<ShelfGroup>? groups}) => Shelf(
    unsorted: unsorted ?? this.unsorted,
    groups: groups ?? this.groups,
    cap: cap,
  );
}
