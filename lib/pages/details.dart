import 'package:cached_network_image/cached_network_image.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:apploook/models/crystal_pricing.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import 'package:apploook/providers/product_configuration_controller.dart';
import 'package:apploook/services/remote_config_service.dart';
import 'package:apploook/widget/modifier_group_widget.dart';
import 'package:apploook/widgets/crystal_pay_toggle.dart';
import 'package:apploook/widgets/crystal_reward_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import 'dart:convert';

final _priceFormat = NumberFormat('#,##0');

// ── Design tokens (kept in line with the rest of the app) ───────────────────
const _kPrimary = AppColors.cxFEC700;
const _kSurface = Color(0xFFF1F2F7);
const _kStepperBg = Color(0xFFD9D9D9);
const _kTextSecondary = Color(0xFFB0B0B0);
const _kTextBody = Color(0xFF5B5B5B);
const _kDivider = Color(0xFFE0E0E0);
const _kError = AppColors.cxC62828;
const _kFont = 'Poppins';

/// The hero artwork is authored at 600×400, so the frame is a 3:2 box that
/// spans the full width and sits on the same white as the rest of the screen —
/// images with a white matte then have no visible edge.
const double _kHeroAspectRatio = 600 / 400;

class Details extends StatefulWidget {
  final dynamic product;

  /// Opens the page with "pay with crystals" already on, for entry points
  /// that are about spending crystals (the crystal shop). The customer can
  /// still switch back to money unless the product is crystal-only.
  final bool payWithCrystals;

  const Details({super.key, this.product, this.payWithCrystals = false});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late final ProductConfigurationController _configuration;

  /// One anchor per modifier group so validation can scroll to the offender.
  final Map<String, GlobalKey> _groupKeys = {};

  final ScrollController _scrollController = ScrollController();

  /// 0 while the hero is on screen, 1 once it has scrolled past the app bar —
  /// drives the title and the hairline that replace it.
  final ValueNotifier<double> _appBarReveal = ValueNotifier<double>(0);

  Product get _product => widget.product as Product;

  /// The customer's choice. Only a request: whether the line really goes
  /// out as a crystal line is decided in [_payingWithCrystals], which also
  /// needs a session and a tier price for the current configuration.
  late bool _payWithCrystals;

  bool get _crystalOnly =>
      CrystalPricing.isCrystalOnly(_product, _configuration.selectedModifiers);

  int? _crystalUnitPrice(LoyaltyTier tier) =>
      CrystalPricing.unitPrice(_product, _configuration.selectedModifiers, tier);

  /// Whether the "pay with crystals" toggle is offered at all: the customer
  /// is signed in and this configuration has a crystal price at their tier.
  bool _crystalOffered(LoyaltyProvider loyalty) =>
      loyalty.hasSession && _crystalUnitPrice(loyalty.tier) != null;

  /// A crystal-only product is always a crystal line, even when it cannot
  /// be bought right now; a money-priced product only while the toggle is
  /// on and the offer stands, so changing modifiers to an unpriced
  /// combination silently falls back to money.
  bool _payingWithCrystals(LoyaltyProvider loyalty) =>
      _crystalOnly || (_payWithCrystals && _crystalOffered(loyalty));

  /// Crystal-only products cannot go into the cart without a session or
  /// without a price at the customer's tier: the server would refuse the
  /// order, so the page refuses first.
  bool _canAddToCart(LoyaltyProvider loyalty) =>
      (!_crystalOnly || _crystalOffered(loyalty)) && _crystalShortfall(loyalty) == 0;

  /// Crystals left for this page once the crystal lines already in the cart
  /// are counted, or null when the balance is unknown or this configuration
  /// is not going out for crystals.
  int? _crystalRoom(LoyaltyProvider loyalty) {
    final budget = loyalty.crystalBudget;
    if (budget == null || !_payingWithCrystals(loyalty)) return null;
    final inCart = CrystalPricing.cartCrystals(
      context.read<CartProvider>().cartItems,
      loyalty.tier,
    );
    return (budget - inCart).clamp(0, budget);
  }

  /// Crystals missing to add the current quantity; 0 when affordable or
  /// when it cannot be told.
  int _crystalShortfall(LoyaltyProvider loyalty) {
    final room = _crystalRoom(loyalty);
    final unit = _crystalUnitPrice(loyalty.tier);
    if (room == null || unit == null) return 0;
    return (unit * _configuration.quantity - room).clamp(0, 1 << 30);
  }

  /// Whether one more unit still fits the crystal balance.
  bool _crystalAllowsMore(LoyaltyProvider loyalty) {
    final room = _crystalRoom(loyalty);
    final unit = _crystalUnitPrice(loyalty.tier);
    if (room == null || unit == null) return true;
    return unit * (_configuration.quantity + 1) <= room;
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (widget.product.description == null) {
      return null;
    }

    // If description is already a Map, use it directly
    if (widget.product.description is Map<String, dynamic>) {
      return widget.product.description[languageCode]?.toString();
    }

    // If description is a String, check if it looks like JSON
    if (widget.product.description is String) {
      String descStr = widget.product.description.toString().trim();
      if (descStr.isEmpty) {
        return null;
      }

      // Only try to parse as JSON if it starts with { or [
      if (descStr.startsWith('{') || descStr.startsWith('[')) {
        try {
          Map<String, dynamic> descriptionMap = json.decode(descStr);
          return descriptionMap[languageCode]?.toString();
        } catch (e) {
          // If JSON parsing fails, fall through to return raw string
        }
      }

      // Return the raw string for non-JSON descriptions
      return descStr;
    }

    // For any other type, convert to string
    return widget.product.description.toString();
  }

  @override
  void initState() {
    super.initState();
    _configuration = ProductConfigurationController(product: _product);
    _payWithCrystals = widget.payWithCrystals ||
        CrystalPricing.isCrystalOnly(_product, const []);
    for (final group in _configuration.groups) {
      _groupKeys[group.id] = GlobalKey();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarReveal.dispose();
    _configuration.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final heroHeight = 1.sw / _kHeroAspectRatio;
    final start = heroHeight * 0.45;
    final end = heroHeight * 0.85;
    final value =
        ((_scrollController.offset - start) / (end - start)).clamp(0.0, 1.0);
    if ((value - _appBarReveal.value).abs() > 0.01 ||
        value == 0 ||
        value == 1) {
      _appBarReveal.value = value;
    }
  }

  // Check if current time is within allowed ordering hours
  // Fetches opening and closing times dynamically from Firebase Remote Config
  // Note: DateTime.now() returns the LOCAL time on the user's device, NOT UTC
  bool _isOrderingTimeAllowed() {
    final remoteConfig = RemoteConfigService();
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Convert current time to minutes since midnight for easier comparison
    final currentTimeInMinutes = currentHour * 60 + currentMinute;

    // Get opening and closing times from Firebase Remote Config
    final openingHour = remoteConfig.openingHour;
    final openingMinute = remoteConfig.openingMinute;
    final closingHour = remoteConfig.closingHour;
    final closingMinute = remoteConfig.closingMinute;

    // Convert to minutes since midnight
    final openingTime = openingHour * 60 + openingMinute;
    final closingTime = closingHour * 60 + closingMinute;

    // Restaurant is CLOSED if:
    // 1. Current time is >= closing time (e.g., from 23:30 to 23:59)
    // 2. Current time is < opening time (e.g., from 00:00 to 09:29)
    if (currentTimeInMinutes >= closingTime ||
        currentTimeInMinutes < openingTime) {
      return false;
    }

    return true;
  }

  // Force refresh Remote Config values
  Future<void> _refreshRemoteConfig() async {
    final remoteConfig = RemoteConfigService();
    final updated = await remoteConfig.forceUpdate();

    // Show a snackbar with the result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remote Config ${updated ? 'updated' : 'not updated'}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Force UI update
      setState(() {});
    }
  }

  void _addToCart() {
    final validation = _configuration.validate();
    if (!validation.isValid) {
      _scrollToGroup(validation.firstInvalidGroup!);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(_requiredOptionsSnackBar());
      return;
    }

    final loyalty = context.read<LoyaltyProvider>();
    if (!_canAddToCart(loyalty)) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCartWithModifiers(_configuration.buildCartItem(
      payWithCrystals: _payingWithCrystals(loyalty),
    ));
    cartProvider.logItems();
    Navigator.pop(context);
  }

  /// Floating white card above the add-to-cart bar: rounded like the rest
  /// of the page, with the brand yellow carrying the "needs attention" cue
  /// instead of a stark black strip.
  SnackBar _requiredOptionsSnackBar() {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.white,
      elevation: 8,
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: const BorderSide(color: _kDivider),
      ),
      content: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.priority_high_rounded,
              size: 20.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).selectRequiredOptions,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToGroup(ModifierGroup group) {
    final anchor = _groupKeys[group.id]?.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      duration: const Duration(milliseconds: 300),
      alignment: 0.1,
      curve: Curves.easeInOut,
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  /// Pinned, white and flat while the hero is visible; once the artwork has
  /// scrolled away the product name and a hairline fade in so the user keeps
  /// their place in a long modifier list.
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56.h,
      titleSpacing: 8.w,
      leadingWidth: 60.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      title: ValueListenableBuilder<double>(
        valueListenable: _appBarReveal,
        builder: (context, reveal, _) => Opacity(
          opacity: reveal,
          child: Text(
            widget.product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: ValueListenableBuilder<double>(
          valueListenable: _appBarReveal,
          builder: (context, reveal, _) => Container(
            height: 1.h,
            color: _kDivider.withValues(alpha: reveal),
          ),
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: _kHeroAspectRatio,
        child: CachedNetworkImage(
          imageUrl: widget.product.imagePath ?? '',
          fit: BoxFit.contain,
          // Artwork is 600×400; cap the decode at 2× that so it stays crisp on
          // 3x screens without holding a needlessly large bitmap.
          memCacheWidth: 1200,
          memCacheHeight: 800,
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48.w,
              color: _kTextSecondary,
            ),
          ),
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: const Color(0xFFEDEEF2),
            highlightColor: Colors.white,
            child: Container(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Product header ────────────────────────────────────────────────────────

  /// Category, name and the crystal choice. The price itself lives only on
  /// the add-to-cart button, so the page never states it twice.
  Widget _buildHeader(LoyaltyProvider loyalty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.categoryTitle.toString().toUpperCase(),
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            height: 1.2,
            color: _kTextSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.product.name,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.3,
            color: Colors.black,
          ),
        ),
        _buildCrystalChoice(loyalty),
      ],
    );
  }

  /// The "pay with crystals" choice under the name. Nothing for a product
  /// that is not sold for crystals; a crystal-only product always says so,
  /// even to a signed-out customer.
  Widget _buildCrystalChoice(LoyaltyProvider loyalty) {
    final crystalOnly = _crystalOnly;
    final unitPrice = _crystalUnitPrice(loyalty.tier);
    final offered = _crystalOffered(loyalty);
    if (!offered && !crystalOnly) return const SizedBox.shrink();

    final Widget body;
    if (offered) {
      body = CrystalPayToggle(
        crystalPrice: unitPrice!,
        value: _payWithCrystals,
        crystalOnly: crystalOnly,
        onChanged: crystalOnly
            ? null
            : (value) => setState(() => _payWithCrystals = value),
      );
    } else if (!loyalty.hasSession) {
      body = const CrystalOnlySignInHint();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CrystalOnlyBadge(),
          SizedBox(height: 4.h),
          Text(
            AppLocalizations.of(context).crystalNotSoldAtTier,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12.sp,
              height: 1.3,
              color: CrystalTheme.textSecondary,
            ),
          ),
        ],
      );
    }
    return Padding(padding: EdgeInsets.only(top: 12.h), child: body);
  }

  Widget _buildDescription() {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final description =
            getDescriptionInLanguage(localeProvider.locale.languageCode)
                ?.trim();
        if (description == null || description.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: Text(
            description,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.55,
              color: _kTextBody,
            ),
          ),
        );
      },
    );
  }

  /// Crystal promo under the description. Scales with the quantity stepper
  /// and the chosen modifiers so the figure is always what this order would
  /// actually earn - and a line paid with crystals earns nothing.
  Widget _buildCrystalReward(LoyaltyProvider loyalty) {
    if (_payingWithCrystals(loyalty)) return const SizedBox.shrink();
    final crystals =
        CrystalPricing.unitPoints(_product, _configuration.selectedModifiers) *
            _configuration.quantity;
    if (crystals <= 0) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: CrystalRewardCard(crystals: crystals),
    );
  }

  Widget _buildModifierGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: const Divider(height: 1, thickness: 1, color: _kDivider),
        ),
        ..._configuration.groups.map(
          (group) => ModifierGroupWidget(
            key: _groupKeys[group.id],
            group: group,
            controller: _configuration,
          ),
        ),
      ],
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildQuantitySelector(LoyaltyProvider loyalty) {
    final quantity = _configuration.quantity;
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: _kStepperBg,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? _configuration.decrementQuantity : null,
          ),
          SizedBox(
            width: 36.w,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          // Paying with crystals, the stepper stops at what the balance
          // (minus what the cart already spends) covers.
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: _crystalAllowsMore(loyalty)
                ? _configuration.incrementQuantity
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(bool canOrder, LoyaltyProvider loyalty) {
    final payingWithCrystals = _payingWithCrystals(loyalty);
    final crystalTotal = payingWithCrystals
        ? (_crystalUnitPrice(loyalty.tier) ?? 0) * _configuration.quantity
        : 0;
    // The label wraps to a second line rather than being truncated — some
    // locales are far longer than "Add to cart", and the button grows with it.
    return ElevatedButton(
      // Disabled after cutoff time, and for a crystal-only product the
      // customer cannot buy (signed out or no price at their tier).
      onPressed: canOrder && _canAddToCart(loyalty) ? _addToCart : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.black,
        disabledBackgroundColor: _kDivider,
        disabledForegroundColor: Colors.black38,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        minimumSize: Size(0, 56.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppLocalizations.of(context).addToCart,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildButtonPrice(payingWithCrystals, crystalTotal),
        ],
      ),
    );
  }

  /// Price on the add-to-cart button. Switching to crystals slides the soum
  /// total up into a struck-through "was" line - what the customer saves -
  /// and the crystal total rises in under it; switching back reverses it.
  /// Quantity and modifier changes re-run the same transition on the figure.
  Widget _buildButtonPrice(bool payingWithCrystals, int crystalTotal) {
    final moneyTotal = '${_priceFormat.format(_configuration.totalPrice)} UZS';
    // A crystal-only product has no soum price worth showing as a saving.
    final showSaving =
        payingWithCrystals && !_crystalOnly && _configuration.totalPrice > 0;
    final priceStyle = TextStyle(
      fontFamily: _kFont,
      fontSize: 15.sp,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    final Widget price = payingWithCrystals
        ? Row(
            key: ValueKey('crystals_$crystalTotal'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(CrystalTheme.asset,
                  width: 20.sp, height: 20.sp),
              SizedBox(width: 5.w),
              Text(
                AppLocalizations.of(context).crystalsAmount(crystalTotal),
                style: priceStyle,
              ),
            ],
          )
        : Text(moneyTotal, key: ValueKey(moneyTotal), style: priceStyle);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: _slideUpTransition,
            child: showSaving
                ? Opacity(
                    key: ValueKey('saving_$moneyTotal'),
                    opacity: 0.55,
                    child: Text(
                      moneyTotal,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no_saving')),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: _slideUpTransition,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerRight,
              children: [...previous, if (current != null) current],
            ),
            child: price,
          ),
        ],
      ),
    );
  }

  static Widget _slideUpTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  /// Shown when the quantity (or switching to crystals) asks for more
  /// crystals than the balance has left; the add button is disabled.
  Widget _buildCrystalShortfallNotice(int shortfall) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: CrystalTheme.lilac,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18.sp, color: CrystalTheme.lilacText),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).notEnoughCrystalsForQuantity(shortfall),
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: CrystalTheme.lilacText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedNotice() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18.sp, color: _kError),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).orderWillBeTaken.trim(),
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: _kError,
              ),
            ),
          ),
          // Debug button to refresh Remote Config (only in debug mode)
          if (kDebugMode)
            IconButton(
              onPressed: _refreshRemoteConfig,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Config',
              visualDensity: VisualDensity.compact,
              color: AppColors.cx1565C0,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(LoyaltyProvider loyalty) {
    final canOrder = _isOrderingTimeAllowed();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kDivider.withValues(alpha: 0.7))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show warning message when ordering is not allowed
              if (!canOrder) _buildClosedNotice(),
              if (_crystalShortfall(loyalty) > 0)
                _buildCrystalShortfallNotice(_crystalShortfall(loyalty)),
              Row(
                children: [
                  _buildQuantitySelector(loyalty),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildAddToCartButton(canOrder, loyalty)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watched here, outside the configuration listeners, so a tier or
    // session change re-prices the page just like a modifier change does.
    final loyalty = context.watch<LoyaltyProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _configuration,
        builder: (context, _) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildHero()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(loyalty),
                  _buildDescription(),
                  _buildCrystalReward(loyalty),
                  // Modifier Groups Section
                  if (_configuration.hasModifiers) _buildModifierGroups(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _configuration,
        builder: (context, _) => _buildBottomBar(loyalty),
      ),
    );
  }
}

// ── Small reusable pieces ─────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Icon(icon, size: 17.sp, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: Icon(
            icon,
            size: 20.sp,
            color: enabled ? Colors.black : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}
