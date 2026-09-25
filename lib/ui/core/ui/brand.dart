import 'package:flutter/material.dart';

import '../themes/colors.dart';
import 'app_icons.dart';

/// 앱 아이콘 96 (radius 22, 레드 + 흰 심볼 66) — 로그인·강제 업데이트
class AppIconMark extends StatelessWidget {
  const AppIconMark({super.key, this.glow = false});

  /// 로그인 화면의 `0 12px 28px -12px rgba(229,64,43,.7)`
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(22),
      boxShadow: glow
          ? [
              BoxShadow(
                color: AppColors.red.withValues(alpha: .7),
                offset: const Offset(0, 12),
                blurRadius: 28,
                spreadRadius: -12,
              ),
            ]
          : null,
    ),
    alignment: Alignment.center,
    child: const SvgIcon(AppIcons.symbolWhite, width: 66, height: 66),
  );
}
