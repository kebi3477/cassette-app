import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/buttons.dart';
import '../view_model/record_view_model.dart';

/// 녹음 · 완료 — 템플릿 `vSent` 블록.
class RecordSentView extends StatelessWidget {
  const RecordSentView({super.key, required this.viewModel});

  final RecordViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Pop(child: _CheckCircle()),
                const SizedBox(height: 16),
                FadeUp(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    vm.sentTitle,
                    textAlign: TextAlign.center,
                    style: AppText.result,
                  ),
                ),
                const SizedBox(height: 16),
                FadeUp(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    vm.sentSub,
                    textAlign: TextAlign.center,
                    style: AppText.suit(
                      500,
                      14,
                      height: 1.5,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomSafe(context)),
          child: vm.sentToNew
              ? Column(
                  children: [
                    AppButton(
                      label: '카카오톡으로 보내기',
                      background: AppColors.kakao,
                      foreground: AppColors.kakaoInk,
                      leading: Container(
                        width: 20,
                        height: 17,
                        decoration: const BoxDecoration(
                          color: AppColors.kakaoInk,
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(10, 8.5),
                          ),
                        ),
                      ),
                      onTap: () => vm.shareLink(ShareChannel.kakao),
                    ),
                    const SizedBox(height: 8),
                    AppButton.soft(
                      label: '문자로 보내기',
                      onTap: () => vm.shareLink(ShareChannel.sms),
                    ),
                  ],
                )
              : AppButton(label: '확인', onTap: vm.finish),
        ),
      ],
    );
  }
}

/// 64 검정 원 안의 체크
class _CheckCircle extends StatelessWidget {
  const _CheckCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      // 22×12, 왼쪽·아래 테두리 3px, rotate(-45deg) translate(2px,-3px)
      child: Transform.rotate(
        angle: -0.7853981633974483,
        child: Transform.translate(
          offset: const Offset(2, -3),
          child: Container(
            width: 22,
            height: 12,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.paper, width: 3),
                bottom: BorderSide(color: AppColors.paper, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
