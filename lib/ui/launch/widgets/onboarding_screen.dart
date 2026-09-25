import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../routing/app_flow.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/parcel_box.dart';
import '../../core/ui/tape_widget.dart';

/// 온보딩 (`auOnb`) — 3장, 다음 / 건너뛰기.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.flow});

  final AppFlow flow;

  /// logic.js `onb` — 설명의 줄바꿈은 화면에서 한 줄로 이어 붙인다(`split('\n').join(' ')`).
  static const pages = [
    ('목소리를 테이프에 담아요', '1분, 3분, 5분. 길이를 골라 하고 싶은 말을 녹음해요'),
    ('소포로 포장해서 보내요', '받는 사람만 뜯어서 들을 수 있어요'),
    ('받은 테이프는 서랍에 모아요', '칸을 만들어 정리하고 이어서 들어요'),
  ];

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _i = 0;

  void _next() {
    if (_i < 2) {
      setState(() => _i++);
    } else {
      widget.flow.finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, sub) = OnboardingScreen.pages[_i];
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: widget.flow.finishOnboarding,
                    child: Text(
                      '건너뛰기',
                      style: AppText.suit(600, 14, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 230,
                    child: Center(
                      child: FadeUp(
                        key: ValueKey(_i),
                        duration: const Duration(milliseconds: 450),
                        child: switch (_i) {
                          0 => const TapeWidget(
                            packL: 40,
                            packR: 42,
                            spinning: true,
                          ),
                          1 => const _ShakingParcel(),
                          _ => const _MiniShelf(),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppText.suit(
                            800,
                            26,
                            height: 1.3,
                            letterSpacingEm: -.02,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sub,
                          textAlign: TextAlign.center,
                          style: AppText.suit(
                            500,
                            15,
                            height: 1.55,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomSafe(context)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var d = 0; d < 3; d++) ...[
                        if (d > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: d == _i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: d == _i
                                ? AppColors.ink
                                : AppColors.toggleOff,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  AppButton(label: _i < 2 ? '다음' : '시작하기', onTap: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2장: 흔들리는 크라프트 박스 (받는 사람 지현)
class _ShakingParcel extends StatefulWidget {
  const _ShakingParcel();

  @override
  State<_ShakingParcel> createState() => _ShakingParcelState();
}

class _ShakingParcelState extends State<_ShakingParcel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
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
        final deg = keyframes(
          _c.value,
          const [0, .7, .75, .8, .85, .9, 1],
          const [0, 0, -3, 3, -2, 2, 0],
          curve: Curves.easeInOut,
        );
        return Transform.rotate(angle: deg * math.pi / 180, child: child);
      },
      child: SizedBox.fromSize(
        size: ParcelBox.size,
        child: const ParcelBoxFront(recipient: '지현'),
      ),
    );
  }
}

/// 3장: 책꽂이 선반 (280 너비, 등 6개)
class _MiniShelf extends StatelessWidget {
  const _MiniShelf();

  static const _spines = [
    (TapePalette.one, '엄마'),
    (TapePalette.three, '지현'),
    (TapePalette.five, '민수'),
    (TapePalette.three, '수아'),
    (TapePalette.one, '하늘'),
    (TapePalette.five, '은비'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 136,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.shelfBoardTop, AppColors.shelfBoardBottom],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, (p, name)) in _spines.indexed) ...[
                  if (i > 0) const SizedBox(width: 3),
                  _Spine(palette: p, name: name),
                ],
              ],
            ),
          ),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.shelfPlank,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: .3),
                  offset: const Offset(0, 5),
                  blurRadius: 8,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spine extends StatelessWidget {
  const _Spine({required this.palette, required this.name});

  final TapePalette palette;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 108,
      decoration: BoxDecoration(
        color: palette.shell,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
          bottom: Radius.circular(1),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: AppColors.black.withValues(alpha: .14)),
          ),
          Positioned(
            left: 5,
            right: 5,
            top: 8,
            height: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.band,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            left: 5,
            right: 5,
            top: 19,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.labelPaper,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final ch in name.characters)
                    Text(ch, style: AppText.suit(700, 11, height: 1.15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
