import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/friend.dart';
import '../domain/models/tape_type.dart';
import '../ui/core/themes/dimens.dart';
import '../ui/friend/view_model/friend_view_model.dart';
import '../ui/friend/widgets/friend_screen.dart';
import '../data/repositories/shelf_repository.dart';
import '../ui/my/view_model/credit_history_view_model.dart';
import '../ui/my/view_model/my_view_model.dart';
import '../ui/my/widgets/credit_history_screen.dart';
import '../ui/my/widgets/my_screen.dart';
import '../ui/player/view_model/player_view_model.dart';
import '../ui/player/widgets/player_screen.dart';
import '../ui/record/view_model/record_view_model.dart';
import '../ui/record/widgets/record_screen.dart';
import '../ui/shelf/view_model/shelf_view_model.dart';
import '../ui/shelf/widgets/shelf_screen.dart';
import '../ui/shell/view_model/shell_view_model.dart';
import '../ui/shell/widgets/app_shell.dart';
import '../ui/shop/view_model/shop_view_model.dart';
import '../ui/shop/widgets/shop_screen.dart';
import 'routes.dart';

/// 탭 4개는 [StatefulShellRoute]로 각자 상태를 유지하고,
/// 재생·친구 화면은 탭바 위(루트 내비게이터)에 띄운다.
GoRouter router({String initialLocation = Routes.record}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(
        navigationShell: shell,
        shellViewModel: context.read<ShellViewModel>(),
        recordViewModel: context.read<RecordViewModel>(),
        shopViewModel: context.read<ShopViewModel>(),
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
              builder: (context, state) => ShelfScreen(
                viewModel: context.read<ShelfViewModel>(),
                onOpen: (item) => context.push(
                  Routes.playItem(
                    item.groupId == null
                        ? const UnsortedSource()
                        : GroupSource(item.groupId!),
                    item.id,
                  ),
                ),
                onReply: (item) {
                  context.read<RecordViewModel>().recordTo(
                    Friend(id: item.senderId!, name: item.from, starred: false),
                  );
                  context.go(Routes.record);
                },
                onGoShop: () => context.go(Routes.shop),
                onGoRecord: () => context.go(Routes.record),
              ),
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
                  viewModel: context.read<ShopViewModel>(),
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
              builder: (context, state) => MyScreen(
                viewModel: context.read<MyViewModel>(),
                onOpenHistory: () => context.push(Routes.credits),
                onGoShop: () => context.go(Routes.shop),
                onOpenFriend: (f) => context.push(Routes.friend(f.id)),
                onRecordTo: (f) {
                  context.read<RecordViewModel>().recordTo(f);
                  context.go(Routes.record);
                },
                onGift: (f) => context.read<ShopViewModel>().openGift(to: f),
                onSignedOut: () {
                  // 로그인 화면은 4단계. 지금은 앱 첫 화면으로 돌아간다.
                  context.read<ShelfRepository>().invalidate();
                  context.go(Routes.record);
                },
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.play,
      pageBuilder: (context, state) => _overlay(
        state,
        PlayerRoute(
          source: QueueSource.parse(state.uri.queryParameters['src'] ?? ''),
          itemId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: Routes.credits,
      pageBuilder: (context, state) => _overlay(state, const CreditsRoute()),
    ),
    GoRoute(
      path: Routes.friendPattern,
      pageBuilder: (context, state) =>
          _overlay(state, FriendRoute(userId: state.pathParameters['userId']!)),
    ),
  ],
);

/// 오버레이 진입 `slideUp .3s` (translateY 40 + 투명 → 제자리). 닫을 때는 바로 사라진다.
Page<void> _overlay(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: AppMotion.slideUp,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (context, animation, _, child) {
    final t = CurvedAnimation(parent: animation, curve: Curves.ease);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t.value)),
          child: child,
        ),
      ),
      child: child,
    );
  },
);

/// 재생 오버레이: 열 때 ViewModel을 만들고, 닫으면 재생을 멈춘다.
class PlayerRoute extends StatefulWidget {
  const PlayerRoute({super.key, required this.source, required this.itemId});

  final QueueSource source;
  final String itemId;

  @override
  State<PlayerRoute> createState() => _PlayerRouteState();
}

class _PlayerRouteState extends State<PlayerRoute> {
  late final PlayerViewModel _vm = PlayerViewModel(
    shelfRepository: context.read(),
    friendRepository: context.read(),
    player: context.read(),
    toast: context.read(),
  );

  @override
  void initState() {
    super.initState();
    _vm.open(widget.source, widget.itemId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerScreen(
      viewModel: _vm,
      onClose: () async {
        await _vm.close();
        if (context.mounted) context.pop();
      },
    );
  }
}

/// 친구 화면: `GET /friends/{userId}/tapes`
class FriendRoute extends StatefulWidget {
  const FriendRoute({super.key, required this.userId});

  final String userId;

  @override
  State<FriendRoute> createState() => _FriendRouteState();
}

class _FriendRouteState extends State<FriendRoute> {
  late final FriendViewModel _vm = FriendViewModel(
    friendRepository: context.read(),
    friendId: widget.userId,
  )..load();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FriendScreen(
      viewModel: _vm,
      onBack: () => context.pop(),
      onPlay: (t) =>
          context.push(Routes.playItem(FriendSource(widget.userId), t.item.id)),
      onRecord: () {
        final f = _vm.friend;
        if (f == null) return;
        context.read<RecordViewModel>().recordTo(f);
        context.go(Routes.record);
      },
    );
  }
}

/// 크레딧 내역: `GET /wallet/ledger`
class CreditsRoute extends StatefulWidget {
  const CreditsRoute({super.key});

  @override
  State<CreditsRoute> createState() => _CreditsRouteState();
}

class _CreditsRouteState extends State<CreditsRoute> {
  late final CreditHistoryViewModel _vm = CreditHistoryViewModel(
    walletRepository: context.read(),
  )..load();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CreditHistoryScreen(
    viewModel: _vm,
    onBack: () => context.pop(),
    onCharge: () => context.go(Routes.shop),
  );
}
