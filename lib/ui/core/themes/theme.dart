import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.paper,
        secondary: AppColors.red,
        onSecondary: AppColors.paper,
        error: AppColors.red,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: AppText.family,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
