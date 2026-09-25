import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../routing/app_flow.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/animations.dart';
import '../../core/ui/app_icons.dart';

/// 스플래시 (`splashOn`) — 전면 레드, 흰 심볼 112(`pop .6s`), 워드마크. 1.4초.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.flow});

  final AppFlow flow;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppFlow.splashTime, widget.flow.finishSplash);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.red,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Pop(
                duration: Duration(milliseconds: 600),
                child: SvgIcon(AppIcons.symbolWhite, width: 112, height: 112),
              ),
              const SizedBox(height: 18),
              FadeUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 250),
                child: Text(
                  'cassette',
                  style: AppText.suit(
                    800,
                    32,
                    height: 1,
                    letterSpacingEm: -.045,
                    color: AppColors.paper,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
