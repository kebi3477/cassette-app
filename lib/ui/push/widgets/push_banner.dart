import 'package:flutter/material.dart';

import '../../auth/widgets/permission_screens.dart' show PushCard;
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../view_model/push_view_model.dart';
import '../../core/ui/tappable.dart';

/// 앱 안 푸시 배너 (`pushOn`) — 위에서 `bannerIn .45s`로 내려오고 6초 뒤 사라진다.
class PushBannerHost extends StatelessWidget {
  const PushBannerHost({super.key, required this.viewModel});

  final PushViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final m = viewModel.banner;
        if (m == null) return const SizedBox.shrink();
        final top = MediaQuery.viewPaddingOf(context).top;
        return Positioned(
          left: 10,
          right: 10,
          top: top > 8 ? top : 8,
          child: _SlideDown(
            key: ValueKey(viewModel.serial),
            child: Semantics(
              button: true,
              child: Tappable(
                onTap: viewModel.tapBanner,
                child: PushCard(
                  title: m.title,
                  body: m.body,
                  background: AppColors.pushBanner,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlideDown extends StatefulWidget {
  const _SlideDown({super.key, required this.child});

  final Widget child;

  @override
  State<_SlideDown> createState() => _SlideDownState();
}

class _SlideDownState extends State<_SlideDown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => FractionalTranslation(
      translation: Offset(0, -1.3 * (1 - AppMotion.snap.transform(_c.value))),
      child: child,
    ),
    child: widget.child,
  );
}
