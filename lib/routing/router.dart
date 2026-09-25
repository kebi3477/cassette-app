import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/links.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/link_service.dart';
import '../data/services/share_service.dart';
import '../domain/models/friend.dart';
import '../domain/models/share_link.dart';
import '../ui/auth/view_model/login_view_model.dart';
import '../ui/auth/view_model/name_view_model.dart';
import '../ui/auth/view_model/permissions_view_model.dart';
import '../ui/auth/widgets/login_screen.dart';
import '../ui/auth/widgets/name_screen.dart';
import '../ui/auth/widgets/permission_screens.dart';
import '../ui/launch/widgets/onboarding_screen.dart';
import '../ui/launch/widgets/splash_screen.dart';
import '../ui/launch/widgets/update_screen.dart';
import '../ui/link/widgets/link_error_screen.dart';
import '../utils/result.dart';
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
import 'app_flow.dart';
import 'routes.dart';

/// 탭 4개는 [StatefulShellRoute]로 각자 상태를 유지하고,
/// 재생·친구 화면은 탭바 위(루트 내비게이터)에 띄운다.
///
/// [flow]가 있으면 처음 실행·로그인 관문을 거친다 (`redirect`).
GoRouter router({
  String initialLocation = Routes.record,
  AppFlow? flow,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: flow,
  redirect: flow == null
      ? null
      : (context, state) => flow.redirect(state.matchedLocation),
  routes: [
    ..._gateRoutes,
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
                openSentId: state.uri.queryParameters['sent'],
                onOpenHistory: () => context.push(Routes.credits),
                onGoShop: () => context.go(Routes.shop),
                onOpenFriend: (f) => context.push(Routes.friend(f.id)),
                onRecordTo: (f) {
                  context.read<RecordViewModel>().recordTo(f);
                  context.go(Routes.record);
                },
                onGift: (f) => context.read<ShopViewModel>().openGift(to: f),
                // 로그아웃·탈퇴하면 관문(redirect)이 로그인 화면으로 보낸다.
                onSignedOut: () => context.read<ShelfRepository>().invalidate(),
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
          linkChip: state.uri.queryParameters['chip'] != '0',
        ),
      ),
    ),
    GoRoute(
      path: Routes.linkError,
      pageBuilder: (context, state) => _overlay(
        state,
        LinkErrorRoute(
          kind: LinkErrorKind.values.byName(
            state.uri.queryParameters['kind'] ?? 'expired',
          ),
          url: state.uri.queryParameters['url'],
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

/// 처음 실행 관문: 스플래시 → 온보딩 → 로그인 → 이름 → 권한 안내 (+ 강제 업데이트)
final _gateRoutes = <RouteBase>[
  GoRoute(
    path: Routes.splash,
    pageBuilder: (context, state) =>
        _fade(state, SplashScreen(flow: context.read())),
  ),
  GoRoute(
    path: Routes.onboarding,
    pageBuilder: (context, state) =>
        _fade(state, OnboardingScreen(flow: context.read())),
  ),
  GoRoute(
    path: Routes.login,
    pageBuilder: (context, state) => _fade(state, const LoginRoute()),
  ),
  GoRoute(
    path: Routes.name,
    pageBuilder: (context, state) => _fade(state, const NameRoute()),
  ),
  GoRoute(
    path: Routes.permissionsMic,
    pageBuilder: (context, state) =>
        _fade(state, const PermissionsRoute(step: PermissionStep.mic)),
  ),
  GoRoute(
    path: Routes.permissionsNoti,
    pageBuilder: (context, state) =>
        _fade(state, const PermissionsRoute(step: PermissionStep.noti)),
  ),
  GoRoute(
    path: Routes.update,
    pageBuilder: (context, state) => _fade(
      state,
      UpdateScreen(
        onUpdate: () {
          final url = context.read<AppFlow>().storeUrl;
          if (url != null) context.read<LinkService>().open(url);
        },
      ),
    ),
  ),
];

/// 관문 화면끼리는 짧게 겹쳐 바뀐다.
Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 250),
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
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
  const PlayerRoute({
    super.key,
    required this.source,
    required this.itemId,
    this.linkChip = true,
  });

  final QueueSource source;
  final String itemId;
  final bool linkChip;

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
    _vm.open(widget.source, widget.itemId, linkChip: widget.linkChip);
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

/// 로그인 (`auLogin`)
class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  late final LoginViewModel _vm = LoginViewModel(
    auth: context.read(),
    toast: context.read(),
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoginScreen(
    viewModel: _vm,
    onOpenTerms: () => context.read<LinkService>().open(AppLinks.terms),
    onOpenPrivacy: () => context.read<LinkService>().open(AppLinks.privacy),
  );
}

/// 이름 정하기 (`auName`)
class NameRoute extends StatefulWidget {
  const NameRoute({super.key});

  @override
  State<NameRoute> createState() => _NameRouteState();
}

class _NameRouteState extends State<NameRoute> {
  late final NameViewModel _vm = NameViewModel(
    auth: context.read(),
    toast: context.read(),
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NameScreen(viewModel: _vm);
}

enum PermissionStep { mic, noti }

/// 권한 안내 (`auMic` → `auNoti`). 실제 OS 권한 창을 띄운다.
class PermissionsRoute extends StatefulWidget {
  const PermissionsRoute({super.key, required this.step});

  final PermissionStep step;

  @override
  State<PermissionsRoute> createState() => _PermissionsRouteState();
}

class _PermissionsRouteState extends State<PermissionsRoute> {
  late final PermissionsViewModel _vm = PermissionsViewModel(
    recorder: context.read(),
    push: context.read(),
    users: context.read(),
    flow: context.read(),
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.step) {
    PermissionStep.mic => MicPromptScreen(
      viewModel: _vm,
      onNext: () => context.go(Routes.permissionsNoti),
    ),
    PermissionStep.noti => NotiPromptScreen(viewModel: _vm),
  };
}

/// 링크 오류 (`leOn`) — 이미 받음 / 만료 / 내 링크
class LinkErrorRoute extends StatefulWidget {
  const LinkErrorRoute({super.key, required this.kind, this.url});

  final LinkErrorKind kind;
  final String? url;

  @override
  State<LinkErrorRoute> createState() => _LinkErrorRouteState();
}

class _LinkErrorRouteState extends State<LinkErrorRoute> {
  String _myName = '';

  @override
  void initState() {
    super.initState();
    context.read<UserRepository>().getMe().then((r) {
      if (r case Ok(:final value) when mounted) {
        setState(() => _myName = value.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) => LinkErrorScreen(
    kind: widget.kind,
    myName: _myName,
    onClose: () => context.pop(),
    onReshare: () async {
      final url = widget.url;
      if (url != null) {
        await context.read<ShareService>().shareText(
          '$_myName님이 테이프를 보냈어요\n$url',
        );
      }
      if (context.mounted) context.pop();
    },
  );
}
