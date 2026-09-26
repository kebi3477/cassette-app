import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../data/services/sound_service.dart';
import 'ui_sound.dart';

/// 햅틱 세기 — 앱 전체가 이 세 가지만 쓴다.
enum Haptic {
  /// 일반 탭 (버튼·행·칩·탭바·시트 행·토글)
  selection,

  /// 데크 키 누름, 길게 눌러 끌기 시작
  medium,

  /// 비활성 버튼 등 — 울리지 않는다
  none;

  void fire() {
    switch (this) {
      case Haptic.selection:
        HapticFeedback.selectionClick();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.none:
        break;
    }
  }

  /// [f]를 부르기 전에 울린다 — [Tappable]을 쓸 수 없는 곳(누름 상태를 따로 다루는 행 등)에서 쓴다.
  VoidCallback? wrap(VoidCallback? f) => f == null
      ? null
      : () {
          fire();
          f();
        };
}

/// 누를 수 있는 모든 요소의 공용 래퍼 — [GestureDetector]와 같지만 누르면 [haptic]을 울린다.
/// [onTap]이 null이면 아무것도 하지 않고 울리지도 않는다.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.onTap,
    this.child,
    this.behavior,
    this.haptic = Haptic.selection,
    this.sound,
    this.excludeFromSemantics = false,
  });

  final VoidCallback? onTap;
  final Widget? child;
  final HitTestBehavior? behavior;
  final Haptic haptic;

  /// 누르면 함께 울릴 효과음 (‹ 뒤로 · ✕ 닫기는 off.wav)
  final UiSound? sound;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    return GestureDetector(
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      onTap: tap == null
          ? null
          : () {
              haptic.fire();
              if (sound case final s?) UiSounds.play(s);
              tap();
            },
      child: child,
    );
  }
}
