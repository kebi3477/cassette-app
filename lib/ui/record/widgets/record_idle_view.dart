import 'package:flutter/material.dart';

import '../../../domain/models/tape_type.dart';
import '../../../utils/format.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/buttons.dart';
import '../view_model/record_view_model.dart';
import 'record_button.dart';
import 'tape_carousel.dart';

/// 녹음 · 대기/녹음 중/멈춤 — 템플릿 `vIdle` 블록.
class RecordIdleView extends StatelessWidget {
  const RecordIdleView({
    super.key,
    required this.viewModel,
    required this.onGoShop,
    required this.onBuyTape,
  });

  final RecordViewModel viewModel;

  /// 0개인 테이프에서 녹음 버튼을 누르면 상점으로 간다 (`goShop`).
  final ValueChanged<TapeType> onGoShop;

  /// 0개인 테이프의 "+" → 상점에서 바로 구매 시트
  final ValueChanged<TapeType> onBuyTape;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final palette = TapePalette.of(vm.tape);
    return Column(
      children: [
        SizedBox(
          height: AppSizes.header,
          child: Center(child: _Header(vm: vm)),
        ),
        Expanded(
          child: ClipRect(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TapeCarousel(
                  selected: vm.tape,
                  owned: vm.wallet.ownedOf,
                  enabled: vm.phase == RecordPhase.idle,
                  onSelect: vm.selectTape,
                  onBuy: onBuyTape,
                  packL: palette.packL(vm.progress),
                  packR: palette.packR(vm.progress),
                  spinning: vm.phase == RecordPhase.rec,
                ),
                const SizedBox(height: 18),
                _LengthRow(selected: vm.tape),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
          child: Center(
            child: _Bottom(vm: vm, onGoShop: onGoShop),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm});

  final RecordViewModel vm;

  @override
  Widget build(BuildContext context) {
    switch (vm.phase) {
      case RecordPhase.rec:
        return FadeUp(
          child: _Timer(
            dot: const Blink(child: _Dot(color: AppColors.red, radius: 4)),
            elapsed: vm.sec,
            max: vm.maxSeconds,
          ),
        );
      case RecordPhase.paused:
        return _Timer(
          dot: const _Dot(color: AppColors.textMuted, radius: 2),
          elapsed: vm.sec,
          max: vm.maxSeconds,
        );
      default:
        if (!vm.showToChip) return const SizedBox.shrink();
        return _ToChip(name: vm.to!.name, onClear: vm.clearTo);
    }
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// `0:12 / 1:00` (700 17, 전체 길이는 `#B5B5B2` 500)
class _Timer extends StatelessWidget {
  const _Timer({required this.dot, required this.elapsed, required this.max});

  final Widget dot;
  final double elapsed;
  final int max;

  @override
  Widget build(BuildContext context) {
    final style = AppText.suit(700, 17, tabularNums: true);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 8),
        Text(formatClock(elapsed), style: style),
        const SizedBox(width: 8),
        Text(
          '/ ${formatClock(max)}',
          style: style.copyWith(
            color: AppColors.textFaint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// "지현에게 ✕" 칩 (높이 34, `#F3F3F1`)
class _ToChip extends StatelessWidget {
  const _ToChip({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$name에게', style: AppText.body),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.toggleOff,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '✕',
                style: AppText.suit(600, 11, height: 1, color: AppColors.paper),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 길이 표시 `1분 3분 5분` (간격 22, `700 14px`)
class _LengthRow extends StatelessWidget {
  const _LengthRow({required this.selected});

  final TapeType selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final t in TapeType.values) ...[
          if (t != TapeType.one) const SizedBox(width: 22),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppText.suit(
                  700,
                  14,
                  color: t == selected ? AppColors.ink : AppColors.textOff,
                ),
                child: Text(TapePalette.of(t).name),
              ),
              const SizedBox(height: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                width: t == selected ? 22 : 4,
                height: 4,
                decoration: BoxDecoration(
                  color: t == selected ? AppColors.ink : AppColors.toggleOff,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.vm, required this.onGoShop});

  final RecordViewModel vm;
  final ValueChanged<TapeType> onGoShop;

  @override
  Widget build(BuildContext context) {
    if (vm.phase == RecordPhase.paused) return _PausedPanel(vm: vm);
    if (vm.mic == MicPermission.denied) {
      return MicDeniedCard(onOpenSettings: vm.openSettings);
    }
    return RecordButton(
      recording: vm.phase == RecordPhase.rec,
      locked: vm.curLocked,
      onTap: () {
        if (vm.phase == RecordPhase.rec) {
          vm.stopRec();
        } else if (vm.curLocked) {
          onGoShop(vm.tape);
        } else {
          vm.startRec();
        }
      },
    );
  }
}

/// 녹음 멈춤 (전화·백그라운드) — `pausedOn`
class _PausedPanel extends StatelessWidget {
  const _PausedPanel({required this.vm});

  final RecordViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: 342,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${vm.pauseWhy}\n${formatClock(vm.sec)}까지 담겼어요',
              textAlign: TextAlign.center,
              style: AppText.suit(
                600,
                14,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton.soft(
                    label: '이어서 녹음',
                    onTap: vm.resumeRec,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(label: '여기까지 쓰기', onTap: vm.useSoFar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 마이크 거부 상태 — `micDeniedOn`
class MicDeniedCard extends StatelessWidget {
  const MicDeniedCard({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 342,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                  child: const CustomPaint(painter: _MicOffPainter()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('마이크가 꺼져 있어요', style: AppText.suit(800, 16)),
                      const SizedBox(height: 3),
                      Text(
                        '설정에서 마이크를 켜야 녹음할 수 있어요',
                        style: AppText.suit(
                          500,
                          13,
                          height: 1.5,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: '설정으로 이동',
              onTap: onOpenSettings,
              height: 48,
              radius: 14,
              textStyle: AppText.suit(700, 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44 원 안의 마이크 + 사선 (CSS 도형)
class _MicOffPainter extends CustomPainter {
  const _MicOffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // 몸통 10×16 at (17,10), radius 6
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 11, 8, 14),
        const Radius.circular(4),
      ),
      stroke,
    );
    // 받침 18×9 at (13,19), 위 테두리 없음, 아래 radius 9
    final cradle = Path()
      ..moveTo(14, 19)
      ..arcToPoint(
        const Offset(30, 19),
        radius: const Radius.circular(8),
        clockwise: false,
      );
    canvas.drawPath(cradle, stroke);
    // 기둥 2×5 at (21,28)
    canvas.drawRect(
      const Rect.fromLTWH(21, 28, 2, 5),
      Paint()..color = AppColors.ink,
    );
    // 사선 2×30 at (21,7), rotate(-45deg), 흰 테두리 2px
    canvas.save();
    canvas.translate(22, 22);
    canvas.rotate(-0.7853981633974483);
    canvas.drawRect(
      const Rect.fromLTWH(-3, -17, 6, 34),
      Paint()..color = AppColors.paper,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-1, -15, 2, 30),
      Paint()..color = AppColors.ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MicOffPainter old) => false;
}
