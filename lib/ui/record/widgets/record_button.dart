import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// 녹음 버튼 (round 스타일). 84 링(`0 0 0 1.5px #E6E6E3`) 안에 64 레드 원.
///
/// 녹음 중에는 30 사각형(radius 7)으로 0.22초 동안 바뀌고 바깥에 `pulse 1.4s` 링이 퍼진다.
/// 0개인 테이프면 `#DADAD7`.
class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    required this.recording,
    required this.locked,
    required this.onTap,
  });

  final bool recording;
  final bool locked;
  final VoidCallback onTap;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording) _pulse.repeat();
  }

  @override
  void didUpdateWidget(RecordButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.recording && _pulse.isAnimating) {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recording;
    return Semantics(
      button: true,
      label: rec ? '녹음 멈추기' : '녹음하기',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // pulse는 box-shadow 전체를 바꾸므로 녹음 중에는 회색 링 대신 펄스만 보인다.
            final t = Curves.easeOut.transform(_pulse.value);
            final shadow = rec
                ? BoxShadow(
                    color: AppColors.recPulse.withValues(
                      alpha: AppColors.recPulse.a * (1 - t),
                    ),
                    spreadRadius: 18 * t,
                  )
                : const BoxShadow(color: AppColors.recRing, spreadRadius: 1.5);
            return Container(
              width: AppSizes.recordButton,
              height: AppSizes.recordButton,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                boxShadow: [shadow],
              ),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.ease,
            width: rec ? 30 : 64,
            height: rec ? 30 : 64,
            decoration: BoxDecoration(
              color: widget.locked ? AppColors.toggleOff : AppColors.red,
              borderRadius: BorderRadius.circular(rec ? 7 : 32),
            ),
          ),
        ),
      ),
    );
  }
}
