import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/shop.dart';
import '../../../domain/models/tape_type.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/tape_palette.dart';
import '../../core/themes/text_styles.dart';
import '../../core/ui/credit_icon.dart';
import '../../core/ui/mini_tape.dart';
import '../../core/ui/skeleton.dart';
import '../view_model/shop_view_model.dart';

/// 상점 탭 — 템플릿 `vShop` 블록. 테이프 → 크레딧 받기 → 서랍.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.viewModel, this.highlight});

  final ShopViewModel viewModel;

  /// 녹음 탭에서 0개인 테이프를 눌러 들어왔을 때 강조할 테이프 (`hl`)
  final TapeType? highlight;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.enter();
    _applyHighlight();
  }

  @override
  void didUpdateWidget(ShopScreen old) {
    super.didUpdateWidget(old);
    if (old.highlight != widget.highlight) _applyHighlight();
  }

  void _applyHighlight() {
    final hl = widget.highlight;
    if (hl == null) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.viewModel.highlightTape(hl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(credits: vm.credits, coinOn: vm.coinOn),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _Body(vm: vm)),
                    if (vm.skeleton)
                      const Positioned.fill(child: _ShopSkeleton()),
                  ],
                ),
              ),
            ],
          ),
          if (vm.flyType != null)
            Positioned(
              left: 171,
              top: 280,
              child: _FlyToMy(
                key: ValueKey(vm.flyType),
                palette: TapePalette.of(vm.flyType!),
              ),
            ),
        ],
      ),
    );
  }
}

/// 헤더: "상점" + 잔액 알약(높이 36, 크레딧 아이콘 22 + `800 15px`)
class _Header extends StatelessWidget {
  const _Header({required this.credits, required this.coinOn});

  final int credits;
  final bool coinOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.header,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('상점', style: AppText.screenTitle),
            Container(
              height: 36,
              padding: const EdgeInsets.only(left: 8, right: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CreditIcon(size: 22),
                      const SizedBox(width: 7),
                      Text(
                        '$credits',
                        style: AppText.suit(800, 15, tabularNums: true),
                      ),
                    ],
                  ),
                  if (coinOn)
                    for (var i = 0; i < 5; i++)
                      Positioned(
                        left: 0,
                        top: 7,
                        child: _CoinFall(
                          delay: Duration(milliseconds: i * 120),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `@keyframes coinFall` .9s ease-in (0.12초 간격) — 충전하면 잔액 알약 위로 떨어진다.
class _CoinFall extends StatefulWidget {
  const _CoinFall({required this.delay});

  final Duration delay;

  @override
  State<_CoinFall> createState() => _CoinFallState();
}

class _CoinFallState extends State<_CoinFall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeIn.transform(_c.value);
          // 0%: translateY(-140) opacity 0 · 15%·85% opacity 1 · 100%: 0, 540deg, opacity 0
          final op = t < .15
              ? t / .15
              : t > .85
              ? (1 - t) / .15
              : 1.0;
          return Opacity(
            opacity: _c.value == 0 ? 0 : op.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -140 * (1 - t)),
              child: Transform.rotate(angle: 3 * math.pi * t, child: child),
            ),
          );
        },
        child: const CreditIcon(size: 22),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});

  final ShopViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.catalog;
    return SingleChildScrollView(
      // 행은 `margin: 0 -12px`로 화면 여백 24보다 12 넓다.
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('테이프', top: 14),
          for (final p in c.tapes)
            _TapeRow(
              product: p,
              owned: vm.ownedOf(p.type),
              highlighted: vm.highlight == p.type && p.qty == 1,
              onTap: () => vm.buy(p),
            ),
          const _SectionTitle('크레딧 받기', top: 24),
          _ShopRow(
            icon: const _GiftIcon(),
            title: '크레딧 선물하기',
            sub: '친구에게 크레딧을 보내요',
            trailing: Text(
              '›',
              style: AppText.suit(
                400,
                20,
                height: 1,
                color: AppColors.disabled,
              ),
            ),
            onTap: vm.openGift,
          ),
          _ShopRow(
            icon: const _AdIcon(),
            title: '광고 보고 받기',
            sub: '오늘 ${vm.adsLeft}번 남음',
            trailing: PricePill(
              label: '+10',
              background: vm.adsLeft > 0 ? AppColors.ink : AppColors.surface,
              foreground: vm.adsLeft > 0
                  ? AppColors.paper
                  : AppColors.textFaint,
            ),
            onTap: vm.openAd,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 12),
              for (var i = 0; i < c.packs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _PackCard(
                    pack: c.packs[i],
                    coins: i + 1,
                    onTap: () => vm.charge(c.packs[i]),
                  ),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
          const _SectionTitle('서랍', top: 24),
          for (final d in c.drawer)
            _ShopRow(
              icon: Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.drawerSwatch,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.black.withValues(alpha: .08),
                  ),
                ),
              ),
              title: d.name,
              sub: '테이프 ${d.slots}개 더 보관 · 지금 ${vm.stored}/${vm.cap}',
              trailing: PricePill(label: '${d.price}'),
              onTap: () => vm.buy(d),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12, top, 12, 8),
    child: Text(text, style: AppText.suit(800, 15)),
  );
}

/// 상점 행 64 (margin 0 −12, padding 0 12, radius 14)
class _ShopRow extends StatefulWidget {
  const _ShopRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.trailing,
    required this.onTap,
    this.flash = false,
  });

  final Widget icon;
  final String title;
  final String sub;
  final Widget trailing;
  final VoidCallback onTap;

  /// 녹음 탭에서 왔을 때 `flash 1.6s`
  final bool flash;

  @override
  State<_ShopRow> createState() => _ShopRowState();
}

class _ShopRowState extends State<_ShopRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: ShopViewModel.highlightTime,
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.flash) _flash.forward();
  }

  @override
  void didUpdateWidget(_ShopRow old) {
    super.didUpdateWidget(old);
    if (widget.flash && !old.flash) _flash.forward(from: 0);
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  Color _bg() {
    if (_flash.isAnimating) {
      final t = _flash.value;
      if (t <= .6) return AppColors.redTint;
      return AppColors.redTint.withValues(
        alpha: 1 - Curves.ease.transform((t - .6) / .4),
      );
    }
    return _pressed
        ? AppColors.surfaceSoft
        : AppColors.surfaceSoft.withValues(alpha: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) => Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _bg(),
            borderRadius: BorderRadius.circular(AppRadius.row),
          ),
          child: child,
        ),
        child: Row(
          children: [
            widget.icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppText.rowTitle),
                  const SizedBox(height: 2),
                  Text(widget.sub, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 14),
            widget.trailing,
          ],
        ),
      ),
    );
  }
}

class _TapeRow extends StatelessWidget {
  const _TapeRow({
    required this.product,
    required this.owned,
    required this.highlighted,
    required this.onTap,
  });

  final TapeProduct product;
  final int owned;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TapePalette.of(product.type);
    final stacked = product.qty > 1;
    return _ShopRow(
      flash: highlighted,
      icon: SizedBox(
        width: 52,
        height: 36,
        child: Stack(
          children: [
            // 5개 묶음은 뒤에 한 장 더, 4px 어긋나게, opacity .6
            if (stacked)
              Positioned(
                left: 4,
                top: 4,
                child: Opacity(opacity: .6, child: MiniTape(palette: p)),
              ),
            MiniTape(palette: p),
          ],
        ),
      ),
      title: product.name,
      sub: '보유 $owned개',
      trailing: PricePill(label: '${product.price}'),
      onTap: onTap,
    );
  }
}

/// 가격 알약 (높이 34, `#111`, 크레딧 아이콘 13 + `800 13.5px`)
class PricePill extends StatelessWidget {
  const PricePill({
    super.key,
    required this.label,
    this.background = AppColors.ink,
    this.foreground = AppColors.paper,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.pricePill,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CreditIcon(size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.suit(
              800,
              13.5,
              color: foreground,
              tabularNums: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// 선물 상자 아이콘 48×36 (`#F3E6E4` 바탕 + 레드 상자·띠)
class _GiftIcon extends StatelessWidget {
  const _GiftIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.giftTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(left: 12, right: 12, top: 12, bottom: 6, child: _box(2)),
          // 뚜껑 (0 0 0 1.5px 바탕색 테두리)
          Positioned(
            left: 8.5,
            right: 8.5,
            top: 7.5,
            height: 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(3.5),
                border: Border.all(color: AppColors.giftTint, width: 1.5),
              ),
            ),
          ),
          const Positioned(
            left: 22,
            width: 4,
            top: 9,
            bottom: 6,
            child: ColoredBox(color: AppColors.giftTint),
          ),
        ],
      ),
    );
  }

  static Widget _box(double r) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

/// 광고 아이콘 48×36 (`#111` + 흰 재생 삼각형)
class _AdIcon extends StatelessWidget {
  const _AdIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: CustomPaint(size: const Size(12, 14), painter: _Tri()),
      ),
    );
  }
}

class _Tri extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.paper,
    );
  }

  @override
  bool shouldRepaint(_Tri old) => false;
}

/// 결제 팩 카드 (`#F6F6F4` radius 16, 크레딧 아이콘 26 1~3개, 금액, 원화)
class _PackCard extends StatefulWidget {
  const _PackCard({
    required this.pack,
    required this.coins,
    required this.onTap,
  });

  final CreditPack pack;
  final int coins;
  final VoidCallback onTap;

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  bool _pressed = false;

  static String _comma(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final n = widget.coins;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 60,
                height: 40,
                child: Stack(
                  children: [
                    // left: 17 + (i − (n−1)/2)·14, bottom: (i%2)·8
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: 17 + (i - (n - 1) / 2) * 14,
                        bottom: (i % 2) * 8.0,
                        child: const CreditIcon(size: 26),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _comma(widget.pack.credits),
                style: AppText.suit(800, 16, tabularNums: true),
              ),
              const SizedBox(height: 10),
              Text(
                widget.pack.priceLabel,
                style: AppText.suit(600, 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 산 테이프가 마이 탭 쪽으로 날아간다 — `flyTab .8s cubic-bezier(.5,-0.3,.7,1)`
class _FlyToMy extends StatefulWidget {
  const _FlyToMy({super.key, required this.palette});

  final TapePalette palette;

  @override
  State<_FlyToMy> createState() => _FlyToMyState();
}

class _FlyToMyState extends State<_FlyToMy>
    with SingleTickerProviderStateMixin {
  static const _curve = Cubic(.5, -.3, .7, 1);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final k = _curve.transform(_c.value);
          return Opacity(
            opacity: (1 - k).clamp(0, 1),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(130 * k, 330 * k, 0)
                ..multiply(Matrix4.diagonal3Values(1 - .7 * k, 1 - .7 * k, 1)),
              child: child,
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: .3),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: MiniTape(palette: widget.palette),
        ),
      ),
    );
  }
}

/// 상점 스켈레톤 (`skShop`)
class _ShopSkeleton extends StatelessWidget {
  const _ShopSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const SkeletonPulse(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            SkeletonBar(width: 48, height: 32, radius: 4),
            SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBar(width: 92, height: 13),
                SizedBox(height: 7),
                SkeletonBar(width: 140, height: 10, light: true),
              ],
            ),
          ],
        ),
      ),
    );
    return ColoredBox(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBar(width: 60, height: 16),
            const SizedBox(height: 6),
            row(),
            row(),
            row(),
            const SizedBox(height: 22),
            const SkeletonBar(width: 90, height: 16),
            const SizedBox(height: 14),
            SkeletonPulse(
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    const Expanded(
                      child: SkeletonBar(
                        width: double.infinity,
                        height: 118,
                        light: true,
                        radius: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
