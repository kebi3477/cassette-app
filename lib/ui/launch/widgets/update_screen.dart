import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/buttons.dart';

/// 강제 업데이트 (`updateOn`) — 업데이트하기 → 스토어
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: FullScreenMessage(
          graphic: const AppIconMark(),
          title: '새 버전이 나왔어요',
          body: '계속 쓰려면 업데이트가 필요해요.\n받은 테이프는 그대로 있어요.',
          button: AppButton(label: '업데이트하기', onTap: onUpdate),
        ),
      ),
    );
  }
}

/// 가운데 그래픽 + 제목(800 24/1.3) + 설명(500 15/1.55) + 하단 56 버튼 — 서버 오류·강제 업데이트
class FullScreenMessage extends StatelessWidget {
  const FullScreenMessage({
    super.key,
    required this.graphic,
    required this.title,
    required this.body,
    required this.button,
  });

  final Widget graphic;
  final String title;
  final String body;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                graphic,
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.suit(
                    800,
                    24,
                    height: 1.3,
                    letterSpacingEm: -.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
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
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomSafe(context)),
          child: button,
        ),
      ],
    );
  }
}
