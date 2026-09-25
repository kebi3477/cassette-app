import 'package:flutter/material.dart';

import '../../../domain/models/shelf.dart';
import '../../../domain/models/tape_item.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/mini_tape.dart';
import '../view_model/shelf_view_model.dart';
import 'shelf_list_view.dart';

/// 책꽂이 보기 — 템플릿 `isShelf` 블록. 선반마다 등 30×108 카세트를 3px 간격으로.
class ShelfBookcase extends StatelessWidget {
  const ShelfBookcase({
    super.key,
    required this.viewModel,
    required this.onOpen,
    required this.onEditGroup,
  });

  final ShelfViewModel viewModel;
  final void Function(TapeItem item) onOpen;
  final void Function(ShelfGroup group) onEditGroup;

  @override
  Widget build(BuildContext context) {
    final s = viewModel.shelf;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                name: ShelfViewModel.unsortedName,
                count: '${s.unsorted.length}개',
                newCount: s.unopenedCount,
                padding: const EdgeInsets.only(bottom: 10),
              ),
              if (s.unsorted.isEmpty)
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '새로 온 테이프가 여기에 들어와요',
                      style: AppText.suit(
                        500,
                        13.5,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 4),
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < s.unsorted.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        _InboxItem(
                          item: s.unsorted[i],
                          onTap: () => onOpen(s.unsorted[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        for (final g in s.groups)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onEditGroup(g),
                  child: SectionHeader(
                    name: g.name,
                    count: '${g.items.length}개',
                    padding: const EdgeInsets.only(bottom: 10),
                  ),
                ),
                _Board(
                  items: g.items,
                  landedId: viewModel.landedId,
                  onOpen: onOpen,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 분류 안 함 칸: 64×44 소포 또는 미니 테이프 + 이름
class _InboxItem extends StatelessWidget {
  const _InboxItem({required this.item, required this.onTap});

  final TapeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 44,
            child: item.opened
                ? Padding(
                    padding: const EdgeInsets.only(left: 8, top: 6),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: MiniTape(palette: TapePalette.of(item.type)),
                    ),
                  )
                : const _BigParcel(),
          ),
          const SizedBox(height: 7),
          Text(item.from, style: AppText.suit(700, 12.5)),
        ],
      ),
    );
  }
}

/// 64×44 크라프트 소포 (테이프 십자 8px)
class _BigParcel extends StatelessWidget {
  const _BigParcel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kraft,
        borderRadius: BorderRadius.circular(4),
        boxShadow: AppShadows.bigParcel,
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 28,
            top: 0,
            bottom: 0,
            width: 8,
            child: ColoredBox(color: AppColors.kraftTape),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 18,
            height: 8,
            child: ColoredBox(color: AppColors.kraftTape),
          ),
        ],
      ),
    );
  }
}

/// 선반: 136 높이 판(`#FBF9F5`→`#F2EDE3`) + 10px 선반 판(`#DDD3C2`)
class _Board extends StatelessWidget {
  const _Board({
    required this.items,
    required this.landedId,
    required this.onOpen,
  });

  final List<TapeItem> items;
  final String? landedId;
  final void Function(TapeItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 136,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.shelfBoardTop, AppColors.shelfBoardBottom],
            ),
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '아직 비어 있어요',
                      style: AppText.suit(
                        500,
                        13.5,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        SizedBox(
                          height: 136,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _Spine(
                              item: items[i],
                              onTap: () => onOpen(items[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        Container(
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.shelfPlank,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            boxShadow: AppShadows.plank,
          ),
        ),
      ],
    );
  }
}

/// 카세트 등 30×108: 위 띠, 가운데 세로쓰기 보낸 사람 이름. 누르는 동안 −8px 들린다(hover).
class _Spine extends StatefulWidget {
  const _Spine({required this.item, required this.onTap});

  final TapeItem item;
  final VoidCallback onTap;

  @override
  State<_Spine> createState() => _SpineState();
}

class _SpineState extends State<_Spine> {
  bool _up = false;

  @override
  Widget build(BuildContext context) {
    final p = TapePalette.of(widget.item.type);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _up = true),
      onTapUp: (_) => setState(() => _up = false),
      onTapCancel: () => setState(() => _up = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: Offset(0, _up ? -8 / 108 : 0),
        child: CustomPaint(
          foregroundPainter: _SpineShade(),
          child: Container(
            width: 30,
            height: 108,
            decoration: BoxDecoration(
              color: p.shell,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
                bottom: Radius.circular(1),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 5,
                  right: 5,
                  top: 8,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.band,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  right: 5,
                  top: 19,
                  bottom: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.labelPaper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    child: _VerticalText(widget.item.from),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `inset -3px 0 0 rgba(0,0,0,.14), inset 2px 0 0 rgba(255,255,255,.1)`
class _SpineShade extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(1),
      bottomRight: const Radius.circular(1),
    );
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 3, 0, 3, size.height),
      Paint()..color = AppColors.black.withValues(alpha: .14),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 2, size.height),
      Paint()..color = AppColors.paper.withValues(alpha: .1),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpineShade old) => false;
}

/// `writing-mode: vertical-rl` — 한글은 글자를 세운 채 위에서 아래로.
class _VerticalText extends StatelessWidget {
  const _VerticalText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ch in text.characters)
            Text(ch, style: AppText.suit(700, 11, height: 1.15)),
        ],
      ),
    );
  }
}
