import 'package:flutter/material.dart';

import '../../../utils/format.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/grain_overlay.dart';
import '../../core/ui/tape_widget.dart';
import '../view_model/record_view_model.dart';

/// 녹음 · 확인 — 템플릿 `vConfirm` 블록.
///
/// 테이프가 `clack .6s`로 떨어지고, 변환하는 동안 노이즈(`grainOn 1.4s`)를 보여준 뒤
/// 자동으로 미리 듣기를 시작한다. 재생 중에는 `wobble 2.4s`와 노이즈 루프.
class RecordConfirmView extends StatelessWidget {
  const RecordConfirmView({super.key, required this.viewModel});

  final RecordViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final palette = TapePalette.of(vm.tape);
    final cp = vm.previewProgress;
    return Column(
      children: [
        BackBar(onBack: vm.backIdle),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Clack(
                child: Wobble(
                  active: vm.playing,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TapeWidget(
                        palette: palette,
                        packL: palette.packL(cp),
                        packR: palette.packR(cp),
                        spinning: vm.playing,
                        speed: 1.8,
                        from: vm.myName,
                      ),
                      if (vm.converting)
                        const Positioned.fill(
                          child: GrainOverlay(mode: GrainMode.once),
                        ),
                      if (vm.playing || vm.convSlow)
                        const Positioned.fill(
                          child: GrainOverlay(mode: GrainMode.loop),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              if (vm.convSlow)
                const _ConvertSlow()
              else if (vm.convFail)
                const _ConvertFail()
              else
                _Preview(vm: vm),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomSafe(context)),
          child: Column(
            children: [
              if (!vm.convFail)
                AppButton(
                  label: vm.sendCta,
                  background: vm.converting
                      ? AppColors.disabled
                      : AppColors.ink,
                  onTap: vm.goSend,
                ),
              if (vm.convFail) ...[
                AppButton(label: '다시 시도', onTap: vm.retryConvert),
                const SizedBox(height: 8),
                AppButton.soft(label: '처음부터 다시 녹음', onTap: vm.redoRec),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 진행 바 + 60 재생 버튼 (너비 260, 간격 18)
class _Preview extends StatelessWidget {
  const _Preview({required this.vm});

  final RecordViewModel vm;

  @override
  Widget build(BuildContext context) {
    final label = AppText.suit(
      600,
      12,
      color: AppColors.textMuted,
      tabularNums: true,
    );
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          Row(
            children: [
              Text(formatClock(vm.pos), style: label),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: AppColors.progressTrack),
                        ),
                        FractionallySizedBox(
                          widthFactor: vm.previewProgress,
                          heightFactor: 1,
                          child: const ColoredBox(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(formatClock(vm.recorded), style: label),
            ],
          ),
          const SizedBox(height: 18),
          PlayButton(playing: vm.playing, onTap: vm.togglePlay),
        ],
      ),
    );
  }
}

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

/// 변환이 1.4초를 넘길 때 — `convSlowOn`
class _ConvertSlow extends StatelessWidget {
  const _ConvertSlow();

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingDots(),
            const SizedBox(height: 12),
            Text('테이프 소리로 바꾸는 중이에요', style: AppText.suit(700, 15)),
            const SizedBox(height: 3),
            Text(
              '조금 오래 걸리고 있어요. 잠시만요',
              style: AppText.suit(500, 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 변환 실패 — `convFailOn`
class _ConvertFail extends StatelessWidget {
  const _ConvertFail();

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('테이프로 바꾸지 못했어요', style: AppText.suit(800, 18)),
            const SizedBox(height: 6),
            Text(
              '녹음은 그대로 있어요. 다시 시도해 볼까요?',
              textAlign: TextAlign.center,
              style: AppText.suit(
                500,
                13.5,
                height: 1.5,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
