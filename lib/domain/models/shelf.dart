import 'tape_item.dart';

/// 사용자 칸 — logic.js `Group`.
class ShelfGroup {
  const ShelfGroup({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<TapeItem> items;
}

/// 서랍 전체 — "분류 안 함"(`inbox`) + 사용자 칸 + 보관 한도.
class Shelf {
  const Shelf({required this.inbox, required this.groups, required this.cap});

  /// 분류 안 함. 새로 받은 테이프가 여기로 들어온다.
  final List<TapeItem> inbox;
  final List<ShelfGroup> groups;

  /// 보관 한도 (처음 12)
  final int cap;

  /// 보관량 = 모든 칸의 테이프 수 + 분류 안 함의 테이프 수
  int get stored =>
      groups.fold<int>(0, (a, g) => a + g.items.length) + inbox.length;

  int get unopenedCount => inbox.where((x) => !x.opened).length;

  bool get hasNew => unopenedCount > 0;
}
