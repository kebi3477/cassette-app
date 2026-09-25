import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// `@keyframes skel{0%,100%{opacity:1}50%{opacity:.45}}` 1.2s ease-in-out infinite
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final k = Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);
        return Opacity(opacity: 1 - .55 * k, child: child);
      },
      child: widget.child,
    );
  }
}

/// 스켈레톤 막대 (`#F0ECE`/`#F4F4F2`)
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.light = false,
    this.radius = 6,
  });

  final double width;
  final double height;
  final bool light;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: light ? AppColors.skeletonLight : AppColors.line,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
