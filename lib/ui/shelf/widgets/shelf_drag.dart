import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/tape_item.dart';
import '../view_model/shelf_view_model.dart';

/// 드래그 정렬의 화면 쪽 처리 — logic.js `rowDown`, `dragMove`, `relY`.
///
/// 드롭할 수 있는 곳(행·칸 제목·빈 칸, 템플릿의 `data-drop`)이 [DropZone]으로 등록되고,
/// 손가락 위치로 [ShelfViewModel.dragOver]에 넘길 [DropTarget]을 계산한다.
class ShelfDragController extends ChangeNotifier {
  ShelfDragController({required this.viewModel, required this.scroll});

  /// 터치: 이만큼 누르고 있으면 드래그 시작 (그 전에 움직이면 스크롤)
  static const holdTime = Duration(milliseconds: 380);

  /// 마우스: 이만큼 움직이면 드래그 시작
  static const double mouseSlop = 6;

  /// 목록 끝에서 이 안으로 들어오면 자동 스크롤
  static const double edge = 56;

  /// 자동 스크롤 한 번에 움직이는 양
  static const double scrollStep = 12;

  final ShelfViewModel viewModel;
  final ScrollController scroll;

  /// 고스트 카드 기준 영역(서랍 본문)과 스크롤 영역
  final GlobalKey areaKey = GlobalKey();
  final GlobalKey viewportKey = GlobalKey();

  final Map<Object, _Zone> _zones = {};

  TapeItem? _item;

  /// 고스트 카드 위치 (영역 위에서 `y − 30`)
  double? _ghostY;

  TapeItem? get ghostItem => _item;
  double? get ghostY => _ghostY;

  void register(Object owner, GlobalKey key, DropTarget target, bool row) =>
      _zones[owner] = _Zone(key, target, row);

  void unregister(Object owner) => _zones.remove(owner);

  void start(TapeItem item, Offset global) {
    viewModel.startDrag(item.id);
    if (!viewModel.dragging) return;
    _item = item;
    move(global);
  }

  void move(Offset global) {
    if (_item == null) return;
    viewModel.dragOver(_hit(global));
    _autoScroll(global.dy);
    final area = _rect(areaKey);
    if (area != null) {
      _ghostY = global.dy - area.top - 30;
      notifyListeners();
    }
  }

  Future<void> end() async {
    if (_item == null) return;
    _item = null;
    _ghostY = null;
    notifyListeners();
    await viewModel.endDrag();
  }

  void cancel() {
    if (_item == null) return;
    _item = null;
    _ghostY = null;
    notifyListeners();
    viewModel.cancelDrag();
  }

  /// 행 위쪽 절반이면 그 앞, 아래쪽 절반이면 그 뒤. 칸 제목·빈 칸이면 그 칸 맨 앞.
  DropTarget? _hit(Offset p) {
    for (final z in _zones.values) {
      final r = _rect(z.key);
      if (r == null || !r.contains(p)) continue;
      var idx = z.target.index;
      if (z.row && p.dy > r.top + r.height / 2) idx++;
      return DropTarget(z.target.groupId, idx);
    }
    return null;
  }

  void _autoScroll(double y) {
    final v = _rect(viewportKey);
    if (v == null || !scroll.hasClients) return;
    final pos = scroll.position;
    double? to;
    if (y > v.bottom - edge) {
      to = pos.pixels + scrollStep;
    } else if (y < v.top + edge) {
      to = pos.pixels - scrollStep;
    }
    if (to != null) {
      scroll.jumpTo(to.clamp(pos.minScrollExtent, pos.maxScrollExtent));
    }
  }

  static Rect? _rect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _Zone {
  _Zone(this.key, this.target, this.row);

  final GlobalKey key;
  final DropTarget target;
  final bool row;
}

/// 템플릿의 `data-drop="gi:idx"` (+ `data-row`).
class DropZone extends StatefulWidget {
  const DropZone({
    super.key,
    required this.controller,
    required this.target,
    this.row = false,
    required this.child,
  });

  final ShelfDragController controller;
  final DropTarget target;
  final bool row;
  final Widget child;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  final GlobalKey _key = GlobalKey();

  void _register() =>
      widget.controller.register(this, _key, widget.target, widget.row);

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(DropZone old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) old.controller.unregister(this);
    _register();
  }

  @override
  void dispose() {
    widget.controller.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// 목록 행의 제스처: 짧게 탭하면 재생, 380ms 누르면(마우스는 6px 움직이면) 드래그.
class DragRowGestures extends StatefulWidget {
  const DragRowGestures({
    super.key,
    required this.controller,
    required this.item,
    required this.onTap,
    required this.child,
  });

  final ShelfDragController controller;
  final TapeItem item;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<DragRowGestures> createState() => _DragRowGesturesState();
}

class _DragRowGesturesState extends State<DragRowGestures> {
  Offset? _mouseDown;
  bool _mouseDragging = false;
  bool _dragged = false;

  ShelfDragController get _c => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _dragged = false;
        if (e.kind == PointerDeviceKind.mouse) {
          _mouseDown = e.position;
          _mouseDragging = false;
        }
      },
      onPointerMove: (e) {
        if (e.kind != PointerDeviceKind.mouse || _mouseDown == null) return;
        if (!_mouseDragging) {
          if ((e.position - _mouseDown!).distance <=
              ShelfDragController.mouseSlop) {
            return;
          }
          _mouseDragging = true;
          _dragged = true;
          _c.start(widget.item, e.position);
          return;
        }
        _c.move(e.position);
      },
      onPointerUp: (e) {
        if (_mouseDragging) _c.end();
        _mouseDown = null;
        _mouseDragging = false;
      },
      onPointerCancel: (e) {
        if (_mouseDragging) _c.cancel();
        _mouseDown = null;
        _mouseDragging = false;
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) {
                  r.onTap = () {
                    if (!_dragged) widget.onTap();
                  };
                },
              ),
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: ShelfDragController.holdTime,
                  supportedDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.invertedStylus,
                  },
                ),
                (r) {
                  r.onLongPressStart = (d) {
                    _dragged = true;
                    _c.start(widget.item, d.globalPosition);
                  };
                  r.onLongPressMoveUpdate = (d) => _c.move(d.globalPosition);
                  r.onLongPressEnd = (_) => _c.end();
                  r.onLongPressCancel = _c.cancel;
                },
              ),
        },
        child: widget.child,
      ),
    );
  }
}
