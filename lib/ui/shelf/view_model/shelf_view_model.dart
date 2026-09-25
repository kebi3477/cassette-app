import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/model/api_error.dart';
import '../../../data/repositories/shelf_repository.dart';
import '../../../domain/models/shelf.dart';
import '../../../domain/models/tape_item.dart';
import '../../../utils/format.dart';
import '../../../utils/result.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/ui/toast.dart';

/// 서랍 보기 — logic.js `shelfView`.
enum ShelfView { list, shelf }

/// 드롭 위치 — logic.js `dropT { gi, idx }`. [groupId]가 null이면 분류 안 함(gi −1).
@immutable
class DropTarget {
  const DropTarget(this.groupId, this.index);

  final String? groupId;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is DropTarget && other.groupId == groupId && other.index == index;

  @override
  int get hashCode => Object.hash(groupId, index);

  @override
  String toString() => 'DropTarget(${groupId ?? 'unsorted'}, $index)';
}

/// 서랍 탭 ViewModel — logic.js의 서랍 부분(`itemRow`, `dragEnd`, `moveTo`, 칸 시트).
class ShelfViewModel extends ChangeNotifier {
  ShelfViewModel({
    required ShelfRepository shelfRepository,
    required this._toast,
  }) : _repo = shelfRepository {
    _repo.addListener(_onRepoChanged);
  }

  /// 탭에 처음 들어갈 때 스켈레톤 `later('skel', 650)`
  static const skeletonTime = Duration(milliseconds: 650);

  /// 옮긴 행 반짝임 `flash 1.2s`
  static const landTime = Duration(milliseconds: 1200);

  static const unsortedName = '분류 안 함';

  final ShelfRepository _repo;
  final ToastController _toast;

  Shelf _shelf = Shelf.empty;
  bool _loaded = false;
  bool _seen = false;
  bool _skeleton = false;
  ShelfView _view = ShelfView.list;
  String? _dragId;
  DropTarget? _drop;
  String? _landed;
  Timer? _skelTimer;
  Timer? _landTimer;

  /// 낙관적 변경 중에는 저장소 알림으로 다시 불러오지 않는다.
  int _pending = 0;

  Shelf get shelf => _shelf;
  bool get loaded => _loaded;
  bool get skeleton => _skeleton;
  ShelfView get view => _view;
  String? get draggingId => _dragId;
  DropTarget? get dropTarget => _drop;
  String? get landedId => _landed;
  bool get dragging => _dragId != null;

  // ── 헤더·배너 (`capText`, `capInk`, `capOn`, `fullOn`, `emptyOn`) ──
  String get capText => '${_shelf.stored}/${_shelf.cap}';
  bool get capFull => _shelf.stored >= _shelf.cap;

  /// 목록 아래 "서랍이 거의 찼어요"
  bool get capNear =>
      _shelf.stored >= _shelf.cap - 2 && _shelf.stored < _shelf.cap;

  /// "서랍이 꽉 찼어요" 배너
  bool get fullOn => _shelf.stored >= _shelf.cap && _shelf.stored > 0;

  /// 빈 서랍 — 분류 안 함도 칸도 없을 때
  bool get emptyOn => _loaded && _shelf.isEmpty;

  /// 행 부제 `09.24 · 3분 · 소포 도착`
  String itemSub(TapeItem x) =>
      '${formatMonthDay(x.date)} · ${TapePalette.of(x.type).name}'
      '${x.groupId == null && !x.opened ? ' · 소포 도착' : ''}';

  /// ⋯ 시트 부제 `09.24 · 칸 이름`
  String sheetSub(TapeItem x) => '${formatMonthDay(x.date)} · ${whereOf(x)}';

  String whereOf(TapeItem x) =>
      x.groupId == null ? unsortedName : (_shelf.group(x.groupId!)?.name ?? '');

  /// 안 뜯은 소포는 옮길 수 없다 (계약서 `PATCH /shelf/items` 409).
  bool canMove(TapeItem x) => x.opened;

  // ── 불러오기 ─────────────────────────────────────
  Future<void> load() async {
    final r = await _repo.getShelf();
    if (r is Ok<Shelf>) {
      _shelf = r.value;
      _loaded = true;
      notifyListeners();
    }
  }

  void _onRepoChanged() {
    if (_pending == 0) load();
  }

  /// 탭에 들어올 때. 처음이면 0.65초 스켈레톤 (`goTab`).
  void enter() {
    if (_seen) return;
    _seen = true;
    // 화면 initState에서 부르므로 알리지 않는다 (곧바로 그 화면이 이 값을 읽는다).
    _skeleton = true;
    _skelTimer = Timer(skeletonTime, () {
      _skeleton = false;
      notifyListeners();
    });
  }

  void setView(ShelfView v) {
    if (_view == v) return;
    _view = v;
    notifyListeners();
  }

  // ── 드래그 정렬 (`rowDown` / `dragMove` / `dragEnd`) ──
  void startDrag(String itemId) {
    final x = _shelf.find(itemId);
    if (x == null || !canMove(x)) return;
    _dragId = itemId;
    _drop = null;
    notifyListeners();
  }

  /// 손가락 아래 드롭 위치. null이면 이전 위치를 유지한다.
  void dragOver(DropTarget? target) {
    if (_dragId == null || target == null || target == _drop) return;
    _drop = target;
    notifyListeners();
  }

  void cancelDrag() {
    _dragId = null;
    _drop = null;
    notifyListeners();
  }

  /// 놓기. 드롭 위치가 없으면 아무 일도 없다.
  Future<void> endDrag() async {
    final id = _dragId, t = _drop;
    _dragId = null;
    _drop = null;
    if (id == null || t == null) {
      notifyListeners();
      return;
    }
    await moveByDrop(id, t);
  }

  /// 드롭 위치로 옮긴다 (`dragEnd`). 같은 칸 안에서 아래로 옮기면 빠진 자리만큼 한 칸 당긴다.
  Future<void> moveByDrop(String itemId, DropTarget t) async {
    final from = _shelf.find(itemId);
    if (from == null) return;
    if (t.groupId != null && _shelf.group(t.groupId!) == null) return;
    var idx = t.index;
    if (from.groupId == t.groupId) {
      final oi = _shelf.itemsOf(t.groupId).indexWhere((x) => x.id == itemId);
      if (oi < idx) idx--;
    }
    await _move(from, t.groupId, idx, toastIfCross: true);
  }

  /// 옮기기 시트 — 그 칸 맨 뒤로 (`moveTo`).
  Future<void> moveTo(String itemId, String? groupId) async {
    final from = _shelf.find(itemId);
    if (from == null) return;
    await _move(from, groupId, null, toastAlways: true);
  }

  Future<void> _move(
    TapeItem item,
    String? groupId,
    int? index, {
    bool toastIfCross = false,
    bool toastAlways = false,
  }) async {
    if (!canMove(item)) return;
    final prev = _shelf;
    final removed = _without(prev, item.id);
    final target = [...removed.itemsOf(groupId)];
    final at = (index ?? target.length).clamp(0, target.length);
    final afterId = at > 0 ? target[at - 1].id : null;
    target.insert(at, item.copyWith(opened: true, groupId: () => groupId));
    _shelf = _withList(removed, groupId, target);
    _landOn(item.id);
    notifyListeners();

    final name = groupId == null
        ? unsortedName
        : '‘${_shelf.group(groupId)!.name}’ 칸';
    if (toastAlways || (toastIfCross && item.groupId != groupId)) {
      _toast.show('$name으로 옮겼어요');
    }

    _pending++;
    final r = await _repo.moveItem(item.id, groupId: groupId, afterId: afterId);
    _pending--;
    if (r case Error(:final error)) {
      _shelf = prev;
      _toast.show(_message(error));
      notifyListeners();
    }
  }

  void _landOn(String id) {
    _landed = id;
    _landTimer?.cancel();
    _landTimer = Timer(landTime, () {
      _landed = null;
      notifyListeners();
    });
  }

  // ── ⋯ 시트 ────────────────────────────────────────
  /// 지우기 (`itemDel`)
  Future<void> deleteItem(String itemId) async {
    final prev = _shelf;
    _shelf = _without(prev, itemId);
    notifyListeners();
    _toast.show('테이프를 지웠어요');
    _pending++;
    final r = await _repo.deleteItem(itemId);
    _pending--;
    if (r case Error(:final error)) {
      _shelf = prev;
      _toast.show(_message(error));
      notifyListeners();
    }
  }

  // ── 칸 시트 (`saveGroup`, `deleteGroup`) ──────────────
  static const int groupNameMax = 12;

  Future<void> addGroup(String draft) async {
    final r = await _repo.createGroup(_groupName(draft));
    switch (r) {
      case Ok<ShelfGroup>(:final value):
        _shelf = _shelf.copyWith(groups: [..._shelf.groups, value]);
        notifyListeners();
        _toast.show('칸을 추가했어요');
      case Error<ShelfGroup>(:final error):
        _toast.show(_message(error));
    }
  }

  Future<void> renameGroup(String groupId, String draft) async {
    final name = _groupName(draft);
    final prev = _shelf;
    _shelf = _shelf.copyWith(
      groups: [
        for (final g in _shelf.groups)
          g.id == groupId ? g.copyWith(name: name) : g,
      ],
    );
    notifyListeners();
    _pending++;
    final r = await _repo.renameGroup(groupId, name);
    _pending--;
    if (r case Error(:final error)) {
      _shelf = prev;
      _toast.show(_message(error));
      notifyListeners();
    }
  }

  /// 칸 지우기 — 안에 있던 테이프는 분류 안 함 맨 뒤로, 뜯은 상태로.
  Future<void> deleteGroup(String groupId) async {
    final g = _shelf.group(groupId);
    if (g == null) return;
    final prev = _shelf;
    _shelf = _shelf.copyWith(
      groups: _shelf.groups.where((x) => x.id != groupId).toList(),
      unsorted: [
        ..._shelf.unsorted,
        for (final x in g.items) x.copyWith(opened: true, groupId: () => null),
      ],
    );
    notifyListeners();
    _toast.show('칸을 지웠어요 · 테이프는 분류 안 함으로');
    _pending++;
    final r = await _repo.deleteGroup(groupId);
    _pending--;
    if (r case Error(:final error)) {
      _shelf = prev;
      _toast.show(_message(error));
      notifyListeners();
    }
  }

  /// 비우면 "새 칸" (`draft.trim() || '새 칸'`)
  static String _groupName(String draft) =>
      draft.trim().isEmpty ? '새 칸' : draft.trim();

  static String _message(Exception e) =>
      e is ApiException ? e.message : '잠시 문제가 생겼어요. 다시 시도해 주세요';

  static Shelf _without(Shelf s, String id) => s.copyWith(
    unsorted: s.unsorted.where((x) => x.id != id).toList(),
    groups: [
      for (final g in s.groups)
        g.copyWith(items: g.items.where((x) => x.id != id).toList()),
    ],
  );

  static Shelf _withList(Shelf s, String? groupId, List<TapeItem> items) =>
      groupId == null
      ? s.copyWith(unsorted: items)
      : s.copyWith(
          groups: [
            for (final g in s.groups)
              g.id == groupId ? g.copyWith(items: items) : g,
          ],
        );

  @override
  void dispose() {
    _skelTimer?.cancel();
    _landTimer?.cancel();
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }
}
