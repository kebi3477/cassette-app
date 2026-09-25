import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/tape_palette.dart';

/// 목록용 미니 테이프 48×32 (서랍 행, 재생 목록, 상점).
class MiniTape extends StatelessWidget {
  const MiniTape({super.key, required this.palette});

  final TapePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.miniTape.width,
      height: AppSizes.miniTape.height,
      decoration: BoxDecoration(
        color: palette.shell,
        borderRadius: BorderRadius.circular(4),
        boxShadow: AppShadows.miniTape,
      ),
      child: CustomPaint(painter: _MiniTapePainter(palette.band)),
    );
  }
}

class _MiniTapePainter extends CustomPainter {
  _MiniTapePainter(this.band);

  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final label = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 42, 17),
      const Radius.circular(2),
    );
    canvas.drawRRect(label, Paint()..color = AppColors.labelPaper);
    canvas.save();
    canvas.clipRRect(label);
    canvas.drawRect(const Rect.fromLTWH(3, 3, 42, 4), Paint()..color = band);
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 10, 22, 8),
        const Radius.circular(2),
      ),
      Paint()..color = TapeInk.hubCore,
    );
    // left:12 right:12 bottom:0 height:7, clip-path polygon(10% 0,90% 0,100% 100%,0 100%)
    final trap = Path()
      ..moveTo(12 + 24 * .1, 25)
      ..lineTo(12 + 24 * .9, 25)
      ..lineTo(36, 32)
      ..lineTo(12, 32)
      ..close();
    canvas.drawPath(trap, Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(_MiniTapePainter old) => old.band != band;
}
