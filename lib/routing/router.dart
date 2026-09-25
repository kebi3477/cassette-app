import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/tape_type.dart';
import '../ui/my/widgets/my_screen.dart';
import '../ui/record/view_model/record_view_model.dart';
import '../ui/record/widgets/record_screen.dart';
import '../ui/shell/view_model/shell_view_model.dart';
import '../ui/shell/widgets/app_shell.dart';
import '../ui/shelf/widgets/shelf_screen.dart';
import '../ui/shop/widgets/shop_screen.dart';
import 'routes.dart';

/// 탭 4개는 [StatefulShellRoute]로 각자 상태를 유지한다.
GoRouter router() => GoRouter(
  initialLocation: Routes.record,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(
        navigationShell: shell,
        shellViewModel: context.read<ShellViewModel>(),
        recordViewModel: context.read<RecordViewModel>(),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.record,
              builder: (context, state) => RecordScreen(
                viewModel: context.read<RecordViewModel>(),
                onGoShop: (t) => context.go(Routes.shopHighlight(t.minutes)),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shelf,
              builder: (context, state) => const ShelfScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shop,
              builder: (context, state) {
                final hl = int.tryParse(state.uri.queryParameters['hl'] ?? '');
                return ShopScreen(
                  key: ValueKey(state.uri.toString()),
                  highlight: hl == null ? null : TapeType.fromMinutes(hl),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.my,
              builder: (context, state) => const MyScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
