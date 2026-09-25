import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// 한 번 재생하는 진입 애니메이션의 공통 뼈대.
abstract class _EntryAnimation extends StatefulWidget {
  const _EntryAnimation({
    super.key,
    required this.child,
    required this.duration,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
}

abstract class _EntryAnimationState<T extends _EntryAnimation> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> t = CurvedAnimation(
    parent: controller,
    curve: Curves.ease,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// `@keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}`
/// 지연이 있으면 `both`처럼 시작 전에도 투명하다.
class FadeUp extends _EntryAnimation {
  const FadeUp({
    super.key,
    required super.child,
    super.duration = AppMotion.fadeUp,
    super.delay,
  });

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends _EntryAnimationState<FadeUp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// `@keyframes slideUp{from{transform:translateY(40px);opacity:0}to{transform:none;opacity:1}}`
class SlideUp extends _EntryAnimation {
  const SlideUp({
    super.key,
    required super.child,
    super.duration = AppMotion.slideUp,
  });

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends _EntryAnimationState<SlideUp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// `@keyframes pop{0%{scale(.6);opacity:0}60%{scale(1.08)}100%{none;opacity:1}}`
class Pop extends _EntryAnimation {
  const Pop({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 400),
  });

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends _EntryAnimationState<Pop> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = controller.value;
        // 구간마다 ease를 적용한다 (CSS animation-timing-function 기본값).
        final double scale;
        final double opacity;
        if (v < .6) {
          final k = Curves.ease.transform(v / .6);
          scale = .6 + (1.08 - .6) * k;
          opacity = k;
        } else {
          final k = Curves.ease.transform((v - .6) / .4);
          scale = 1.08 + (1 - 1.08) * k;
          opacity = 1;
        }
        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// `@keyframes blink{50%{opacity:.2}}` + `1s steps(1) infinite`
class Blink extends StatefulWidget {
  const Blink({super.key, required this.child});

  final Widget child;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
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
      builder: (context, child) =>
          Opacity(opacity: _c.value < .5 ? 1 : .2, child: child),
      child: widget.child,
    );
  }
}

/// 키프레임을 구간별 곡선으로 보간한다.
/// [stops]는 0~1 오름차순, [values]는 같은 길이.
double keyframes(
  double t,
  List<double> stops,
  List<double> values, {
  Curve curve = Curves.ease,
}) {
  if (t <= stops.first) return values.first;
  for (var i = 1; i < stops.length; i++) {
    if (t <= stops[i]) {
      final span = stops[i] - stops[i - 1];
      final k = span == 0 ? 1.0 : curve.transform((t - stops[i - 1]) / span);
      return values[i - 1] + (values[i] - values[i - 1]) * k;
    }
  }
  return values.last;
}
