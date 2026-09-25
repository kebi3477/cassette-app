import 'package:flutter/material.dart';

import '../../../utils/format.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/grain_overlay.dart';
import '../../core/ui/tape_motion.dart';
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
