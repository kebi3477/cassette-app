import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/text_styles.dart';
import 'tappable.dart';

enum AppTab { record, shelf, shop, my }

/// 탭바 — 템플릿 `showTabs` 블록. 높이 84, 위 경계선 1px, 4칸, 위 패딩 10.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.current,
    required this.onTap,
    this.hasNew = false,
  });

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  /// 서랍에 안 뜯은 테이프가 있으면 서랍 아이콘 오른쪽 위에 레드 점
  final bool hasNew;

  static const _labels = {
    AppTab.record: '녹음',
    AppTab.shelf: '서랍',
    AppTab.shop: '상점',
    AppTab.my: '마이',
  };

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    // 기준 화면은 홈 인디케이터 34px을 포함해 84다.
    final height = inset > 34 ? 50 + inset : AppSizes.tabBar;
    return Container(
      height: height,
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tab in AppTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == current,
                label: _labels[tab],
                excludeSemantics: true,
                child: Tappable(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(tab),
                  child: _TabItem(
                    tab: tab,
                    on: tab == current,
                    label: _labels[tab]!,
                    dot: tab == AppTab.shelf && hasNew,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.on,
    required this.label,
    required this.dot,
  });

  final AppTab tab;
  final bool on;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final ink = on ? AppColors.ink : AppColors.textFaint;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: CustomPaint(
                    painter: TabIconPainter(tab: tab, ink: ink, on: on),
                  ),
                ),
                const SizedBox(height: 5),
                Text(label, style: AppText.tab.copyWith(color: ink)),
              ],
            ),
          ),
          if (dot)
            Positioned(
              top: 0,
              left: box.maxWidth * .56,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 탭 아이콘 22×22 — 원본은 CSS 도형(테두리 2px)이다.
class TabIconPainter extends CustomPainter {
  TabIconPainter({required this.tab, required this.ink, required this.on});

  final AppTab tab;
  final Color ink;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = ink;
    switch (tab) {
      case AppTab.record:
        // 22 원 테두리 2 + 가운데 8 점 (켜지면 레드)
        canvas.drawCircle(const Offset(11, 11), 10, stroke);
        canvas.drawCircle(
          const Offset(11, 11),
          4,
          Paint()..color = on ? AppColors.red : ink,
        );
      case AppTab.shelf:
        // 서랍장: 바깥 상자(inset 2, radius 3) + 가운데 가로줄 + 손잡이 두 개
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 16, 16),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawRect(const Rect.fromLTWH(2, 10, 18, 2), fill);
        final r1 = RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 6, 6, 2),
          const Radius.circular(1),
        );
        canvas.drawRRect(r1, fill);
        canvas.drawRRect(r1.shift(const Offset(0, 8)), fill);
      case AppTab.shop:
        // 손잡이: left 6, top 0, 10×9, 위 모서리 6
        // (radius 6+6이 너비 10을 넘어 CSS가 5로 줄인다 → 선 중심 반지름 4)
        final handle = Path()
          ..moveTo(7, 9)
          ..lineTo(7, 5)
          ..arcToPoint(const Offset(11, 1), radius: const Radius.circular(4))
          ..arcToPoint(const Offset(15, 5), radius: const Radius.circular(4))
          ..lineTo(15, 9);
        canvas.drawPath(handle, stroke);
        // 가방: left 2 right 2 top 6 bottom 1, radius 3 3 5 5
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            const Rect.fromLTWH(3, 7, 16, 13),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(4),
          ),
          stroke,
        );
      case AppTab.my:
        // 머리: left 6 top 1, 10×10 원
        canvas.drawCircle(const Offset(11, 6), 4, stroke);
        // 어깨: left 2 right 2 bottom 1, 높이 8, 위 모서리 9, 아래 테두리 없음
        // (세로 반지름 9가 높이 8을 넘어 CSS가 8로 줄인다 → 선 중심 반지름 7)
        final body = Path()
          ..moveTo(3, 21)
          ..arcToPoint(const Offset(10, 14), radius: const Radius.circular(7))
          ..lineTo(12, 14)
          ..arcToPoint(const Offset(19, 21), radius: const Radius.circular(7));
        canvas.drawPath(body, stroke);
    }
  }

  @override
  bool shouldRepaint(TabIconPainter old) =>
      old.tab != tab || old.ink != ink || old.on != on;
}
