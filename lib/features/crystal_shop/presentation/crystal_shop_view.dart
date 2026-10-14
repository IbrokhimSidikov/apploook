import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/widget/banner_widget.dart';
import '../application/crystal_shop_controller.dart';
import '../domain/crystal_shop_models.dart';
import 'crystal_theme.dart';

final _fmt = NumberFormat('#,##0', 'en_US');

/// Shop half of the Crystal Shop: the spinning promo carousel, then a grid
/// of rewards that can only be bought with crystals.
class CrystalShopView extends StatelessWidget {
  const CrystalShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      color: CrystalTheme.violet,
      onRefresh: () => controller.loadShop(silent: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 18.h)),
          SliverToBoxAdapter(
            child: BannerCarouselWidget(
              banners: controller.banners,
              isLoading: controller.bannersLoading,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 12.h),
              child: Row(
                children: [
                  Expanded(
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
                  if (controller.items.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: CrystalTheme.lilac,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${controller.items.length}',
                        style: TextStyle(
                          fontFamily: CrystalTheme.font,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: CrystalTheme.lilacText,
                        ),
                      ),
                    ),
                ],
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
        return [const _ShimmerGrid()];
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
        if (controller.items.isEmpty) {
          return [SliverToBoxAdapter(child: _EmptyState(message: l.shopEmpty))];
        }
        return [
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
                (context, i) => _ItemCard(item: controller.items[i]),
                childCount: controller.items.length,
              ),
            ),
          ),
        ];
    }
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final CrystalShopItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final affordable = controller.canAfford(item);
    final shortfall = controller.shortfall(item);

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
            // Artwork on a tinted plate with the category tag.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF4F1FB),
                    padding: EdgeInsets.all(14.r),
                    child: _ItemImage(path: item.imagePath),
                  ),
                  if (item.category.isNotEmpty)
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            fontFamily: CrystalTheme.font,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: CrystalTheme.lilacText,
                          ),
                        ),
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
                  if (!affordable && shortfall > 0) ...[
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

// ── Redeem flow ─────────────────────────────────────────────────────────────

/// Bottom sheet confirming a redemption, then the code to show at the counter.
class RedeemSheet extends StatelessWidget {
  const RedeemSheet({super.key, required this.item});

  final CrystalShopItem item;

  static Future<void> show(BuildContext context, CrystalShopItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RedeemSheet(item: item),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = context.read<CrystalShopController>();
    final result = await controller.redeem(item);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.redeemFailed),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      builder: (_) => _SuccessDialog(item: item, code: result.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final balance = controller.balance ?? 0;
    final affordable = controller.canAfford(item);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

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
              color: const Color(0xFFF4F1FB),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: _ItemImage(path: item.imagePath),
          ),
          SizedBox(height: 16.h),
          Text(
            item.name,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: CrystalTheme.ink,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              item.description,
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
                      l.balanceAfter,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 11.sp,
                        color: CrystalTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _fmt.format((balance - item.crystalPrice).clamp(0, 1 << 30)),
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: affordable
                            ? CrystalTheme.ink
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 54.h,
            child: ElevatedButton(
              onPressed: affordable && !controller.isRedeeming
                  ? () => _confirm(context)
                  : null,
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
              child: controller.isRedeeming
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: CrystalTheme.ink,
                      ),
                    )
                  : Text(
                      affordable
                          ? l.spendCrystals(item.crystalPrice)
                          : l.needMoreCrystals(controller.shortfall(item)),
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.item, required this.code});

  final CrystalShopItem item;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: const BoxDecoration(
                gradient: CrystalTheme.header,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(CrystalTheme.asset, width: 46.w),
            ),
            SizedBox(height: 16.h),
            Text(
              l.redeemSuccessTitle,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: CrystalTheme.ink,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '${item.name}\n${l.redeemSuccessBody}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 13.sp,
                height: 1.5,
                color: CrystalTheme.textSecondary,
              ),
            ),
            if (code.isNotEmpty) ...[
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: CrystalTheme.lilac,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: CrystalTheme.violetBright.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: CrystalTheme.lilacText,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrystalTheme.yellow,
                  foregroundColor: CrystalTheme.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                ),
                child: Text(
                  l.done,
                  style: TextStyle(
                    fontFamily: CrystalTheme.font,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
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
