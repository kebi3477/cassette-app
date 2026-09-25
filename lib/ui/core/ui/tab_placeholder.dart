import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import '../themes/text_styles.dart';

/// 아직 만들지 않은 탭의 자리 — 헤더 60 + 제목(800 24)만 둔다.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSizes.header,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: AppText.screenTitle),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
