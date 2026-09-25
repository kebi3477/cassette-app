import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/friend.dart';
import '../../../domain/models/sent_tape.dart';
import '../../../domain/models/tape_type.dart';
import '../../../domain/models/user.dart';
import '../../../utils/format.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/credit_icon.dart';
import '../../core/ui/skeleton.dart';
import '../view_model/my_view_model.dart';
import 'my_sheets.dart';

/// 마이 탭 — 템플릿 `vMy` 블록.
class MyScreen extends StatefulWidget {
  const MyScreen({
    super.key,
    required this.viewModel,
    required this.onOpenHistory,
    required this.onGoShop,
    required this.onOpenFriend,
    required this.onRecordTo,
    required this.onGift,
    required this.onSignedOut,
  });

  final MyViewModel viewModel;
  final VoidCallback onOpenHistory;
  final VoidCallback onGoShop;
  final ValueChanged<Friend> onOpenFriend;

  /// 친구 ⋯ > 녹음해서 보내기
  final ValueChanged<Friend> onRecordTo;

  /// 친구 ⋯ > 크레딧 선물하기
  final ValueChanged<Friend> onGift;

  /// 로그아웃·탈퇴 뒤 (로그인 화면은 4단계)
  final VoidCallback onSignedOut;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final TextEditingController _name = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.viewModel.enter();
    // 입력칸에서 벗어나면 저장 (`onBlur={{ doneName }}`)
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) widget.viewModel.commitName();
    });
    // 보낸 테이프: 끝 가까이 오면 다음 페이지
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 400) widget.viewModel.loadMoreSent();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _startEdit() {
    final vm = widget.viewModel;
    vm.startEditName();
    _name.text = vm.nameDraft;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nameFocus.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: AppSizes.header,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('마이', style: AppText.screenTitle),
                    ),
                  ),
                  _nameBlock(vm),
                  _CreditRow(credits: vm.credits, onTap: widget.onOpenHistory),
                  const SizedBox(height: 10),
                  _Stats(vm: vm),
                  _SectionHeader(
                    title: '보유 테이프',
                    top: 20,
                    bottom: 12,
                    action: '상점 ›',
                    onAction: widget.onGoShop,
                  ),
                  _Drawer(vm: vm),
                  const _SectionHeader(title: '친구', top: 26, bottom: 6),
                  for (final f in vm.friends)
                    _FriendRow(
                      friend: f,
                      onTap: () => widget.onOpenFriend(f),
                      onStar: () => vm.toggleStar(f),
                      onMore: () => showFriendSheet(
                        context,
                        friend: f,
                        onRecord: () => widget.onRecordTo(f),
                        onGift: () => widget.onGift(f),
                        onRemove: () => vm.removeFriend(f),
                        onBlock: () => vm.block(f),
                      ),
                    ),
                  const _SectionHeader(title: '보낸 테이프', top: 26, bottom: 10),
                  _SentCard(
                    vm: vm,
                    onTap: (s) => showSentDetailSheet(
                      context,
                      sent: s,
                      onReshare: () => vm.reshare(s),
                    ),
                  ),
                  const _SectionHeader(title: '설정', top: 26, bottom: 4),
                  _SettingRow(
                    label: '알림',
                    onTap: vm.toggleNotifications,
                    trailing: _Toggle(on: vm.notificationsOn),
                  ),
                  _SettingRow(
                    label: '연결된 계정',
                    trailing: _Value(vm.providerText),
                  ),
                  _SettingRow(
                    label: '크레딧 내역',
                    onTap: widget.onOpenHistory,
                    trailing: const _Chevron(),
                  ),
                  _SettingRow(
                    label: '차단한 친구',
                    onTap: () => showBlockedSheet(context, viewModel: vm),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Value(vm.blockedCountText),
                        const SizedBox(width: 8),
                        const _Chevron(),
                      ],
                    ),
                  ),
                  const _SectionHeader(title: '정보', top: 26, bottom: 4),
                  _SettingRow(
                    label: '이용약관',
                    onTap: () => vm.openDoc(AppDoc.terms),
                    trailing: const _Chevron(),
                  ),
                  _SettingRow(
                    label: '개인정보 처리방침',
                    onTap: () => vm.openDoc(AppDoc.privacy),
                    trailing: const _Chevron(),
                  ),
                  _SettingRow(
                    label: '문의하기',
                    onTap: () => vm.openDoc(AppDoc.contact),
                    trailing: const _Chevron(),
                  ),
                  _SettingRow(
                    label: '앱 버전',
                    trailing: _Value(vm.version, tabular: true),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(top: 14, bottom: 4),
                    color: AppColors.line,
                  ),
                  _SettingRow(
                    label: '로그아웃',
                    onTap: () async {
                      await vm.logout();
                      widget.onSignedOut();
                    },
                  ),
                  _SettingRow(
                    label: '회원 탈퇴',
                    color: AppColors.textFaint,
                    onTap: () => showWithdrawSheet(
                      context,
                      viewModel: vm,
                      onDone: widget.onSignedOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.skeleton)
            const Positioned(
              left: 0,
              right: 0,
              top: AppSizes.header,
              bottom: 0,
              child: _MySkeleton(),
            ),
        ],
      ),
    );
  }

  /// 이름(800 21) + "수정", 설명 "테이프에 적히는 이름이에요"
  Widget _nameBlock(MyViewModel vm) {
    const underline = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.ink, width: 2),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: vm.editingName
                ? TextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    onChanged: vm.setNameDraft,
                    onSubmitted: (_) => _nameFocus.unfocus(),
                    style: AppText.suit(800, 21),
                    cursorColor: AppColors.ink,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        User.maxNameLength,
                        maxLengthEnforcement:
                            MaxLengthEnforcement.truncateAfterCompositionEnds,
                      ),
                    ],
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: underline,
                      focusedBorder: underline,
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _startEdit,
                    child: Row(
                      children: [
                        Text(vm.name, style: AppText.suit(800, 21)),
                        const SizedBox(width: 8),
                        Text(
                          '수정',
                          style: AppText.suit(
                            600,
                            12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 2),
          Text('테이프에 적히는 이름이에요', style: AppText.caption),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.top,
    required this.bottom,
    this.action,
    this.onAction,
  });

  final String title;
  final double top;
  final double bottom;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: bottom),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppText.suit(800, 16)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppText.suit(600, 13, color: AppColors.textMuted),
            ),
          ),
      ],
    ),
  );
}

/// 크레딧 행 56 (`#F6F6F4` radius 16)
class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credits, required this.onTap});

  final int credits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const CreditIcon(size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text('크레딧', style: AppText.suit(600, 14.5))),
          Text('$credits', style: AppText.suit(800, 16, tabularNums: true)),
          const SizedBox(width: 10),
          const _Chevron(),
        ],
      ),
    ),
  );
}

/// 통계 3칸
class _Stats extends StatelessWidget {
  const _Stats({required this.vm});

  final MyViewModel vm;

  @override
  Widget build(BuildContext context) {
    Widget cell(int n, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text('$n', style: AppText.suit(800, 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.suit(500, 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        cell(vm.receivedCount, '받은 테이프'),
        cell(vm.sentCount, '보낸 테이프'),
        cell(vm.friendCount, '친구'),
      ],
    );
  }
}

/// 보유 테이프 3칸 (1분 "무료", 3·5분 "N개", 0이면 레드·테이프 opacity .4)
class _Drawer extends StatelessWidget {
  const _Drawer({required this.vm});

  final MyViewModel vm;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, t) in TapeType.values.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: _DrawerCard(type: t, owned: vm.ownedOf(t)),
        ),
      ],
    ],
  );
}

class _DrawerCard extends StatelessWidget {
  const _DrawerCard({required this.type, required this.owned});

  final TapeType type;
  final int owned;

  @override
  Widget build(BuildContext context) {
    final p = TapePalette.of(type);
    final zero = !type.isUnlimited && owned <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: zero ? .4 : 1,
            child: _BigMiniTape(palette: p),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: AppText.suit(700, 13),
              children: [
                TextSpan(text: '${p.name} '),
                TextSpan(
                  text: type.isUnlimited ? '무료' : '$owned개',
                  style: TextStyle(
                    color: zero ? AppColors.red : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 보유 테이프 카드의 56×36 미니 테이프
class _BigMiniTape extends StatelessWidget {
  const _BigMiniTape({required this.palette});

  final TapePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 36,
    decoration: BoxDecoration(
      color: palette.shell,
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: .25),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: 3,
          right: 3,
          top: 3,
          height: 19,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Column(
              children: [
                Container(height: 5, color: palette.band),
                const Expanded(child: ColoredBox(color: AppColors.labelPaper)),
              ],
            ),
          ),
        ),
        Positioned(
          left: 15,
          right: 15,
          top: 11,
          height: 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TapeInk.hubCore,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 0,
          height: 8,
          child: ClipPath(
            clipper: _Trapezoid(),
            child: ColoredBox(color: AppColors.black.withValues(alpha: .2)),
          ),
        ),
      ],
    ),
  );
}

class _Trapezoid extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .1, 0)
    ..lineTo(s.width * .9, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_Trapezoid old) => false;
}

/// 친구 행 58: 이름, ☆, ⋯ (margin 0 −12, padding 0 4 0 12)
class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.onTap,
    required this.onStar,
    required this.onMore,
  });

  final Friend friend;
  final VoidCallback onTap;
  final VoidCallback onStar;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(child: Text(friend.name, style: AppText.suit(700, 15))),
            Semantics(
              button: true,
              label: friend.starred ? '즐겨찾기 해제' : '즐겨찾기',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onStar,
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: Text(
                      friend.starred ? '★' : '☆',
                      style: AppText.suit(
                        400,
                        19,
                        height: 1,
                        color: friend.starred
                            ? AppColors.star
                            : AppColors.disabled,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: '${friend.name} 더 보기',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMore,
                child: SizedBox(
                  width: 36,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: const BoxDecoration(
                            color: AppColors.textFaint,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 보낸 테이프 카드 (`#FAFAF8` + `inset 0 0 0 1px #EFEFEC`)
class _SentCard extends StatelessWidget {
  const _SentCard({required this.vm, required this.onTap});

  final MyViewModel vm;
  final ValueChanged<SentTape> onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.sentCard,
      borderRadius: BorderRadius.circular(AppRadius.button),
      border: Border.all(color: AppColors.cardStroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in vm.sent)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(s),
            child: Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 14,
                    decoration: BoxDecoration(
                      color: TapePalette.of(s.type).shell,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: AppColors.black.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${s.to}에게 보냄',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${formatMonthDay(s.date)} · ${MyViewModel.sentStatus(s)}',
                    style: AppText.suit(
                      500,
                      12.5,
                      color: AppColors.textMuted,
                      tabularNums: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '›',
                    style: AppText.suit(
                      400,
                      18,
                      height: 1,
                      color: AppColors.disabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '보낸 테이프는 받은 사람만 들을 수 있어요',
              style: AppText.suit(500, 12, color: AppColors.textFaint),
            ),
          ),
        ),
      ],
    ),
  );
}

/// 설정 행 52 (`600 15px`)
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    this.onTap,
    this.trailing,
    this.color = AppColors.ink,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.suit(600, 15, color: color)),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.tabular = false});

  final String text;
  final bool tabular;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.suit(
      500,
      13.5,
      color: AppColors.textMuted,
      tabularNums: tabular,
    ),
  );
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Text(
    '›',
    style: AppText.suit(400, 20, height: 1, color: AppColors.disabled),
  );
}

/// 알림 토글 48×28 (켜짐 `#111`, 꺼짐 `#DADAD7`, 손잡이 22)
class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      color: on ? AppColors.ink : AppColors.toggleOff,
      borderRadius: BorderRadius.circular(14),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: .2),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 마이 스켈레톤 (`skMy`)
class _MySkeleton extends StatelessWidget {
  const _MySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const SkeletonPulse(
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBar(width: 72, height: 14),
            SkeletonBar(width: 20, height: 20, light: true, radius: 10),
          ],
        ),
      ),
    );
    return ColoredBox(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonPulse(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBar(width: 120, height: 22),
                  SizedBox(height: 26),
                  SkeletonBar(
                    width: double.infinity,
                    height: 56,
                    light: true,
                    radius: 16,
                  ),
                  SizedBox(height: 26),
                  SkeletonBar(width: 50, height: 16),
                ],
              ),
            ),
            row(),
            row(),
            row(),
            row(),
          ],
        ),
      ),
    );
  }
}
