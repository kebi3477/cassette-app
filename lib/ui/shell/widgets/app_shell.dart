import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/themes/colors.dart';
import '../../core/ui/tab_bar.dart';
import '../../record/view_model/record_view_model.dart';
import '../view_model/shell_view_model.dart';

/// 상태바 → 본문 → 탭바 84. 녹음 확인부터 완료까지는 탭바를 숨긴다.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.shellViewModel,
    required this.recordViewModel,
  });

  final StatefulNavigationShell navigationShell;
  final ShellViewModel shellViewModel;
  final RecordViewModel recordViewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListenableBuilder(
        listenable: Listenable.merge([shellViewModel, recordViewModel]),
        builder: (context, _) {
          final current = AppTab.values[navigationShell.currentIndex];
          final showTabs =
              current != AppTab.record || !recordViewModel.hidesTabs;
          return Column(
            children: [
              Expanded(child: SafeArea(bottom: false, child: navigationShell)),
              if (showTabs)
                AppTabBar(
                  current: current,
                  hasNew: shellViewModel.hasNew,
                  onTap: (tab) => navigationShell.goBranch(
                    tab.index,
                    initialLocation: tab.index == navigationShell.currentIndex,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
