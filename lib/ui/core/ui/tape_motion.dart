import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'animations.dart';

/// 60 검정 재생/일시정지 버튼
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? '일시정지' : '재생',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSizes.playButton,
          height: AppSizes.playButton,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: playing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_bar(), const SizedBox(width: 5), _bar()],
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: CustomPaint(
                    size: const Size(16, 20),
                    painter: _TrianglePainter(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bar() => Container(
    width: 4,
    height: 17,
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.paper);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

/// 점 3개 (`dot 1.2s ease-in-out`, 0 · .15 · .3초 지연)
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
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
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _dot((_c.value - i * .125) % 1),
          ],
        ],
      ),
    );
  }

  Widget _dot(double t) {
    // 0%,80%,100%{opacity:.25} 40%{opacity:1; translateY(-3px)}
    final k = keyframes(
      t,
      const [0, .4, .8, 1],
      const [0, 1, 0, 0],
      curve: Curves.easeInOut,
    );
    return Transform.translate(
      offset: Offset(0, -3 * k),
      child: Opacity(
        opacity: .25 + .75 * k,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// `@keyframes clack` — 테이프가 위에서 툭 떨어진다 (.6s, cubic-bezier(.3,.7,.3,1)).
class Clack extends StatefulWidget {
  const Clack({super.key, required this.child});

  final Widget child;

  @override
  State<Clack> createState() => _ClackState();
}

class _ClackState extends State<Clack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          keyframes(
            _c.value,
            const [0, .45, .7, 1],
            const [-34, 5, -2, 0],
            curve: AppMotion.settle,
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// `@keyframes wobble` — 재생 중 살짝 흔들린다 (2.4s ease-in-out infinite).
class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(Wobble old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.reset();
    }
  }

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
        if (!widget.active) return child!;
        final t = _c.value;
        const stops = [0.0, .5, 1.0];
        final deg = keyframes(t, stops, const [
          -.8,
          .6,
          -.8,
        ], curve: Curves.easeInOut);
        final dy = keyframes(t, stops, const [
          0,
          -1,
          0,
        ], curve: Curves.easeInOut);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: deg * 3.141592653589793 / 180,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
