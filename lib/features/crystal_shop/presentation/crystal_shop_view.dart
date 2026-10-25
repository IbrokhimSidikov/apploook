import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/cart_provider.dart';
import 'package:apploook/pages/app_shell.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/crystal_pricing.dart';
import 'package:apploook/pages/details.dart';
import '../application/crystal_shop_controller.dart';
import '../domain/crystal_shop_models.dart';
import 'crystal_rank_board.dart';
import 'crystal_theme.dart';
import 'crystal_toast.dart';

final _fmt = NumberFormat('#,##0', 'en_US');

/// Shop half of the Crystal Shop: the customer's level board, then the
/// menu products sold for crystals at the customer's tier, one grid per
/// menu category, with a pinned row of category tabs like the home menu.
class CrystalShopView extends StatefulWidget {
  const CrystalShopView({super.key});

  @override
  State<CrystalShopView> createState() => _CrystalShopViewState();
}

class _CrystalShopViewState extends State<CrystalShopView> {
  final _scroll = ScrollController();
  final _tabScroll = ScrollController();
  final _tabBarKey = GlobalKey();

  /// Section headers and tab labels, keyed by category id.
  final _sectionKeys = <int, GlobalKey>{};
  final _tabKeys = <int, GlobalKey>{};

  /// Category id of the highlighted tab; null means the first section.
  int? _selected;

  /// True while animating to a tapped section, so the scroll listener does
  /// not flick the highlight through every section on the way.
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncSelected);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _tabScroll.dispose();
    super.dispose();
  }

  GlobalKey _sectionKey(int id) => _sectionKeys.putIfAbsent(id, GlobalKey.new);
  GlobalKey _tabKey(int id) => _tabKeys.putIfAbsent(id, GlobalKey.new);

  /// Screen y of the pinned tab bar's bottom edge: a section counts as the
  /// current one once its header has scrolled up to that line.
  double? _tabBarBottom() {
    final box = _tabBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(Offset(0, box.size.height)).dy;
  }

  void _syncSelected() {
    if (_jumping || !mounted) return;
    final sections = context.read<CrystalShopController>().sections;
    final line = _tabBarBottom();
    if (sections.isEmpty || line == null) return;

    int? index;
    if (_scroll.position.extentAfter < 1) {
      // The last section may be too short to ever reach the line.
      index = sections.length - 1;
    } else {
      // Headers far off screen are not built; skip them. The first built
      // header still below the line means the one before it is current.
      for (var i = 0; i < sections.length; i++) {
        final box = _sectionKeys[sections[i].categoryId]
            ?.currentContext
            ?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;
        if (box.localToGlobal(Offset.zero).dy <= line + 1) {
          index = i;
        } else {
          index ??= i > 0 ? i - 1 : 0;
          break;
        }
      }
    }
    if (index == null) return;

    final id = sections[index].categoryId;
    if (id != (_selected ?? sections.first.categoryId)) {
      setState(() => _selected = id);
      _revealTab(id);
    }
  }

  /// Scrolls the tab row so the tab for [id] sits in the middle.
  void _revealTab(int id) {
    final box = _tabKeys[id]?.currentContext?.findRenderObject();
    if (box == null || !_tabScroll.hasClients) return;
    final offset = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.5);
    _tabScroll.animateTo(
      offset.offset.clamp(0.0, _tabScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _jumpToSection(int index) async {
    final controller = context.read<CrystalShopController>();
    final sections = controller.sections;
    final id = sections[index].categoryId;
    HapticFeedback.selectionClick();
    setState(() => _selected = id);
    _revealTab(id);
    if (!_scroll.hasClients) return;

    _jumping = true;
    try {
      // An off-screen section is not built yet, so it has no position to
      // reveal. Jump roughly there by its share of the items first.
      if (_sectionKeys[id]?.currentContext == null) {
        final before = sections
            .take(index)
            .fold<int>(0, (sum, section) => sum + section.items.length);
        final position = _scroll.position;
        position.jumpTo(
          position.maxScrollExtent * before / controller.itemCount,
        );
        await WidgetsBinding.instance.endOfFrame;
      }

      final box = _sectionKeys[id]?.currentContext?.findRenderObject();
      final barHeight = (_tabBarKey.currentContext?.findRenderObject()
                  as RenderBox?)
              ?.size
              .height ??
          0;
      if (box == null || !mounted) return;
      // Reveal at the top, then back off by the pinned bar covering it.
      final target =
          RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset -
              barHeight;
      await _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _jumping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      color: CrystalTheme.violet,
      onRefresh: controller.refreshShop,
      child: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 18.h)),
          const SliverToBoxAdapter(child: CrystalRankBoard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 4.h),
              child: Text(
                l.redeemWithCrystals,
                style: TextStyle(
                  fontFamily: CrystalTheme.font,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: CrystalTheme.ink,
                ),
              ),
            ),
          ),
          ..._buildBody(context, controller),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 20.h)),
        ],
      ),
    );
  }

  List<Widget> _buildBody(
      BuildContext context, CrystalShopController controller) {
    final l = AppLocalizations.of(context);

    switch (controller.shopState) {
      case CrystalLoadState.idle:
      case CrystalLoadState.loading:
        return [
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          const _ShimmerGrid(),
        ];
      case CrystalLoadState.signedOut:
      case CrystalLoadState.error:
        return [
          SliverToBoxAdapter(
            child: _EmptyState(
              message: l.shopEmpty,
              action: l.retry,
              onAction: controller.loadShop,
            ),
          ),
        ];
      case CrystalLoadState.ready:
        final sections = controller.sections;
        if (sections.isEmpty) {
          return [SliverToBoxAdapter(child: _EmptyState(message: l.shopEmpty))];
        }
        // A tier change can drop the highlighted category.
        final selected = sections.any((s) => s.categoryId == _selected)
            ? _selected!
            : sections.first.categoryId;
        return [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabsDelegate(
              child: _CategoryTabs(
                key: _tabBarKey,
                scrollController: _tabScroll,
                sections: sections,
                selected: selected,
                tabKey: _tabKey,
                onTap: _jumpToSection,
              ),
            ),
          ),
          for (final (i, section) in sections.indexed) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                key: _sectionKey(section.categoryId),
                title: section.title,
                first: i == 0,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ItemCard(item: section.items[i]),
                  childCount: section.items.length,
                ),
              ),
            ),
          ],
        ];
    }
  }
}

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  _CategoryTabsDelegate({required this.child});

  final Widget child;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 50.h;

  @override
  double get minExtent => 50.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

/// Horizontal row of category names, the current one dark and bold with a
/// violet underline, the rest grey; same idea as the home menu's tabs.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    super.key,
    required this.scrollController,
    required this.sections,
    required this.selected,
    required this.tabKey,
    required this.onTap,
  });

  final ScrollController scrollController;
  final List<CrystalShopSection> sections;
  final int selected;
  final GlobalKey Function(int categoryId) tabKey;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      color: CrystalTheme.page,
      // Not a lazy ListView: every tab must be laid out so the selected one
      // can be scrolled into view.
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            for (final (i, section) in sections.indexed)
              _CategoryTab(
                key: tabKey(section.categoryId),
                title: section.title,
                active: section.categoryId == selected,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 14.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? CrystalTheme.ink : const Color(0xFFB0B0B0),
              ),
              child: Text(title),
            ),
            SizedBox(height: 4.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3.h,
              width: active ? 18.w : 0,
              decoration: BoxDecoration(
                color: CrystalTheme.violet,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category heading above each grid.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.first,
  });

  final String title;

  /// The first section sits right under the shop title, so it needs less
  /// space above it than the gap between two grids.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, first ? 8.h : 26.h, 20.w, 12.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: CrystalTheme.violet,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: CrystalTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final CrystalShopItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final inCart = context.select<CartProvider, int>(
        (cart) => CrystalPricing.cartCrystals(cart.cartItems, controller.tier));
    final affordable = controller.canAfford(item, inCart: inCart);
    final shortfall = controller.shortfall(item, inCart: inCart);
    // "Need N more" only means something once the balance is known.
    final showShortfall =
        !affordable && controller.balance != null && shortfall > 0;

    return GestureDetector(
      onTap: () => RedeemSheet.show(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: CrystalTheme.card,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: CrystalTheme.border),
          boxShadow: [
            BoxShadow(
              color: CrystalTheme.violet.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork on white, matching the product photos' own background.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(14.r),
                    child: _ItemImage(path: item.imagePath),
                  ),
                  if (item.isCrystalOnly)
                    Positioned(
                      bottom: 10.h,
                      left: 10.w,
                      child: _Tag(
                        text: l.crystalOnly,
                        background: CrystalTheme.violet,
                        foreground: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: CrystalTheme.ink,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: CrystalPrice(amount: item.crystalPrice)),
                      SizedBox(width: 6.w),
                      Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: affordable
                              ? CrystalTheme.yellow
                              : const Color(0xFFEDEBF4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          affordable
                              ? Icons.arrow_forward_rounded
                              : Icons.lock_outline_rounded,
                          size: 16.sp,
                          color: affordable
                              ? CrystalTheme.ink
                              : CrystalTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (showShortfall) ...[
                    SizedBox(height: 6.h),
                    Text(
                      l.needMoreCrystals(shortfall),
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        color: CrystalTheme.textSecondary,
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

/// Small uppercase pill used for the crystal-only badge.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: CrystalTheme.font,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: foreground,
        ),
      ),
    );
  }
}

/// Crystal icon plus amount, in the shop's lilac tint.
class CrystalPrice extends StatelessWidget {
  const CrystalPrice({super.key, required this.amount, this.large = false});

  final int amount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 22.w : 15.w;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(CrystalTheme.asset, width: iconSize, height: iconSize),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            _fmt.format(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: large ? 22.sp : 14.sp,
              fontWeight: FontWeight.w700,
              color: CrystalTheme.lilacText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders either a bundled asset or a network image, with a shimmer while
/// the latter loads.
class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Icon(Icons.card_giftcard_rounded,
          size: 40.w, color: CrystalTheme.textSecondary);
    }
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        memCacheWidth: 500,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Icon(Icons.image_not_supported_outlined,
            size: 36.w, color: CrystalTheme.textSecondary),
      );
    }
    return Image.asset(path, fit: BoxFit.contain);
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: const Color(0xFFEDEBF4),
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 30.h, 32.w, 10.h),
      child: Column(
        children: [
          Container(
            width: 84.w,
            height: 84.w,
            decoration: const BoxDecoration(
              color: CrystalTheme.lilac,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(CrystalTheme.asset, width: 44.w),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 14.sp,
              height: 1.45,
              color: CrystalTheme.textSecondary,
            ),
          ),
          if (action != null) ...[
            SizedBox(height: 14.h),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: CrystalTheme.lilacText,
                textStyle: TextStyle(
                  fontFamily: CrystalTheme.font,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pay with crystals ──────────────────────────────────────────────────────

/// What the sheet asked the card to do after it closed. Navigation and the
/// snackbar happen from the card's context, which outlives the sheet.
enum _SheetResult { added, configure, signIn }

/// Bottom sheet showing the product and its crystal price, with a single
/// "Pay with crystals" button that puts the line in the cart.
class RedeemSheet extends StatelessWidget {
  const RedeemSheet({super.key, required this.item});

  final CrystalShopItem item;

  static Future<void> show(BuildContext context, CrystalShopItem item) async {
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RedeemSheet(item: item),
    );
    if (result == null || !context.mounted) return;
    final l = AppLocalizations.of(context);

    switch (result) {
      case _SheetResult.signIn:
        Navigator.pushNamed(context, '/signin');
      case _SheetResult.configure:
        // Modifiers to choose: the details page adds the line itself.
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => Details(product: item.product, payWithCrystals: true),
          ),
        );
      case _SheetResult.added:
        context.read<CartProvider>().addToCartWithModifiers(
              CartItem(product: item.product, payWithCrystals: true),
            );
        HapticFeedback.mediumImpact();
        CrystalToast.show(
          context,
          message: '${item.name} · ${l.addedToCart}',
          actionLabel: l.cart,
          // The shop is a shell tab, so show the cart tab in place; only
          // fall back to the standalone route outside the shell.
          onAction: () {
            if (!AppShell.select(context, AppShell.cartTab)) {
              Navigator.pushNamed(context, '/cart');
            }
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final balance = controller.balance;
    final hasSession = controller.hasSession;
    // Crystals already committed in the cart count against the balance, so
    // adding again cannot overdraw it.
    final inCart = context.select<CartProvider, int>(
        (cart) => CrystalPricing.cartCrystals(cart.cartItems, controller.tier));
    final affordable = controller.canAfford(item, inCart: inCart);
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final description =
        item.descriptionFor(Localizations.localeOf(context).languageCode);

    final _SheetResult? action;
    final String label;
    if (!hasSession) {
      action = _SheetResult.signIn;
      label = l.signIn;
    } else if (affordable) {
      action = item.needsConfiguration
          ? _SheetResult.configure
          : _SheetResult.added;
      label = l.payWithCrystals;
    } else {
      action = null;
      label = balance == null
          ? l.payWithCrystals
          : l.needMoreCrystals(controller.shortfall(item, inCart: inCart));
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, bottom + 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            height: 170.h,
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: CrystalTheme.border),
            ),
            child: _ItemImage(path: item.imagePath),
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: CrystalTheme.font,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: CrystalTheme.ink,
                  ),
                ),
              ),
              if (item.isCrystalOnly) ...[
                SizedBox(width: 10.w),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: _Tag(
                    text: l.crystalOnly,
                    background: CrystalTheme.violet,
                    foreground: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 14.sp,
                height: 1.5,
                color: CrystalTheme.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: CrystalTheme.lilac,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              children: [
                CrystalPrice(amount: item.crystalPrice, large: true),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasSession ? l.balanceAfter : l.yourCrystals,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 11.sp,
                        color: CrystalTheme.textSecondary,
                      ),
                    ),
                    Text(
                      balance == null
                          ? '—'
                          : _fmt.format((balance - inCart - item.crystalPrice)
                              .clamp(0, 1 << 30)),
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: affordable || balance == null
                            ? CrystalTheme.ink
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!hasSession) ...[
            SizedBox(height: 12.h),
            Text(
              l.crystalOnlyNeedsSignIn,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 12.5.sp,
                height: 1.4,
                color: CrystalTheme.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            height: 54.h,
            child: ElevatedButton(
              onPressed: action == null
                  ? null
                  : () => Navigator.of(context).pop(action),
              style: ElevatedButton.styleFrom(
                backgroundColor: CrystalTheme.yellow,
                foregroundColor: CrystalTheme.ink,
                disabledBackgroundColor: const Color(0xFFEDEBF4),
                disabledForegroundColor: CrystalTheme.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (action == _SheetResult.added ||
                      action == _SheetResult.configure) ...[
                    SvgPicture.asset(CrystalTheme.asset,
                        width: 18.w, height: 18.w),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
