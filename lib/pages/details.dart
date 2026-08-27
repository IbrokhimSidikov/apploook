import 'package:cached_network_image/cached_network_image.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/providers/product_configuration_controller.dart';
import 'package:apploook/services/remote_config_service.dart';
import 'package:apploook/widget/modifier_group_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

class Details extends StatefulWidget {
  final dynamic product;

  const Details({super.key, this.product});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late final ProductConfigurationController _configuration;

  /// One anchor per modifier group so validation can scroll to the offender.
  final Map<String, GlobalKey> _groupKeys = {};

  Product get _product => widget.product as Product;

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
    for (final group in _configuration.groups) {
      _groupKeys[group.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _configuration.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).selectRequiredOptions),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCartWithModifiers(_configuration.buildCartItem());
    cartProvider.logItems();
    Navigator.pop(context);
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

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
          child: Container(
            width: double.infinity,
            color: _kSurface,
            padding: EdgeInsets.fromLTRB(20.w, topInset + 56.h, 20.w, 20.h),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: widget.product.imagePath ?? '',
                fit: BoxFit.contain,
                // Detail screen is full-width; cap decode at 1200×900 physical
                // px — enough for any phone screen.
                memCacheWidth: 1200,
                memCacheHeight: 900,
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48.w,
                    color: _kTextSecondary,
                  ),
                ),
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: const Color(0xFFE6E7EC),
                  highlightColor: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topInset + 8.h,
          left: 16.w,
          child: _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  // ── Product header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.categoryTitle.toString().toUpperCase(),
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: _kTextSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          widget.product.name,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '${_priceFormat.format(_configuration.basePrice)} UZS',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
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
          padding: EdgeInsets.only(top: 16.h),
          child: Text(
            description,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1.55,
              color: _kTextBody,
            ),
          ),
        );
      },
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

  Widget _buildQuantitySelector() {
    final quantity = _configuration.quantity;
    return Container(
      height: 52.h,
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
            width: 40.w,
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
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: _configuration.incrementQuantity,
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(bool canOrder) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: canOrder ? _addToCart : null, // Disabled after cutoff time
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _kDivider,
          disabledForegroundColor: Colors.black38,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '${_priceFormat.format(_configuration.totalPrice)} UZS',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12.r),
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

  Widget _buildBottomBar() {
    final canOrder = _isOrderingTimeAllowed();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show warning message when ordering is not allowed
              if (!canOrder) _buildClosedNotice(),
              Row(
                children: [
                  _buildQuantitySelector(),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildAddToCartButton(canOrder)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _configuration,
        builder: (context, _) => CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  _buildDescription(),
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
        builder: (context, _) => _buildBottomBar(),
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
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Icon(icon, size: 18.sp, color: Colors.black),
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
          width: 40.w,
          height: 40.w,
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
