import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/unified_order_tracking_page.dart';
import 'package:apploook/providers/loyalty_provider.dart';

final _money = NumberFormat('#,##0', 'en_US');

/// What the success page reports about an order that just went through.
///
/// Captured from the loyalty hold before it is committed: committing resets
/// the checkout quote, so these figures cannot be read back afterwards.
class OrderSuccessDetails {
  /// Checkout tab: 0 delivery, 1 self-pickup, 2 carhop, 3 in-restaurant.
  final int orderTypeIndex;

  /// Soum charged with money (card) or still due at the counter (cash).
  final double moneyTotal;
  final bool paidByCard;

  /// Crystals taken off the card for the crystal lines.
  final int crystalsSpent;

  /// Crystals this order earns. They land as pending and turn spendable
  /// later, which the page says plainly.
  final int crystalsEarned;

  const OrderSuccessDetails({
    required this.orderTypeIndex,
    required this.moneyTotal,
    required this.paidByCard,
    this.crystalsSpent = 0,
    this.crystalsEarned = 0,
  });
}

/// Full-screen confirmation shown after an order is accepted, in place of
/// the old success dialogs: the order is in, what it cost in soum and
/// crystals, and the crystals it added to the customer's balance.
///
/// It replaces the whole stack (the cart is already cleared), so back and
/// both buttons lead home rather than to a spent checkout.
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.details});

  final OrderSuccessDetails details;

  /// Clears the stack down to this page, so back cannot reach the checkout.
  static Future<void> show(BuildContext context, OrderSuccessDetails details) {
    return Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderSuccessPage(details: details)),
      (route) => false,
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/homeNew', (_) => false);
  }

  void _trackOrder(BuildContext context) {
    Navigator.of(context)
      ..pushNamedAndRemoveUntil('/homeNew', (_) => false)
      ..push(MaterialPageRoute(
        builder: (_) => UnifiedOrderTrackingPage(initialTab: _trackingTab),
      ));
  }

  /// Tracking tab for the order: the checkout tabs are delivery, self-pickup,
  /// carhop, in-restaurant; tracking groups them as delivery, carhop, and
  /// self-pickup with in-restaurant.
  int get _trackingTab => switch (details.orderTypeIndex) {
        0 => 0,
        2 => 1,
        _ => 2,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  MediaQuery.of(context).padding.top + 36.h,
                  20.w,
                  24.h,
                ),
                child: Column(
                  children: [
                    const _SuccessMark(),
                    SizedBox(height: 22.h),
                    Text(
                      l.orderReceivedTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.cx0B0B0B,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l.orderReceivedBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 14.sp,
                        height: 1.45,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _SummaryCard(details: details),
                    if (details.crystalsEarned > 0) ...[
                      SizedBox(height: 16.h),
                      _EarnedCard(crystals: details.crystalsEarned),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottom + 16.h),
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () => _goHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cxFEC700,
                        foregroundColor: AppColors.cx0B0B0B,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                      child: Text(
                        l.backToHome,
                        style: TextStyle(
                          fontFamily: CrystalTheme.font,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextButton(
                    onPressed: () => _trackOrder(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.cx0B0B0B,
                    ),
                    child: Text(
                      l.trackOrderButton,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

/// Green check that pops in with a slight overshoot, on a soft halo.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: 112.w,
        height: 112.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE3F5EA),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 76.w,
          height: 76.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1FA45B),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1FA45B).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: Colors.white, size: 44.sp),
        ),
      ),
    );
  }
}

/// Order type, the soum part and the crystal part of the payment.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.details});

  final OrderSuccessDetails details;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final orderType = switch (details.orderTypeIndex) {
      1 => l.selfPickup,
      2 => l.carhop,
      3 => l.inRestaurant,
      _ => l.delivery,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.orderSummary,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.cx0B0B0B,
            ),
          ),
          SizedBox(height: 6.h),
          _Row(
            icon: Icons.storefront_outlined,
            label: l.orderTypeLabel,
            value: Text(orderType, style: _Row.valueStyle),
          ),
          _Row(
            icon: details.paidByCard
                ? Icons.credit_card_rounded
                : Icons.payments_outlined,
            label: details.paidByCard ? l.paidByCard : l.payInCash,
            value: Text(
              '${_money.format(details.moneyTotal)} ${l.currency}',
              style: _Row.valueStyle,
            ),
          ),
          if (details.crystalsSpent > 0)
            _Row(
              leading: SvgPicture.asset(CrystalTheme.asset,
                  width: 24.w, height: 24.w),
              label: l.crystalsSpent,
              value: Text(
                '− ${l.crystalsAmount(details.crystalsSpent)}',
                style: _Row.valueStyle.copyWith(color: CrystalTheme.lilacText),
              ),
              last: true,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;
  final Widget value;
  final bool last;

  static final valueStyle = TextStyle(
    fontFamily: CrystalTheme.font,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.cx0B0B0B,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            child: leading ??
                Icon(icon, size: 19.sp, color: Colors.grey.shade500),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 13.5.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          value,
        ],
      ),
    );
  }
}

/// The crystals this order added, on the same violet board as the Crystal
/// Shop header, with the customer's balance underneath.
class _EarnedCard extends StatelessWidget {
  const _EarnedCard({required this.crystals});

  final int crystals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Refreshed by LoyaltyProvider.confirm() right before this page opens.
    final loyalty = context.watch<LoyaltyProvider>();
    final balance = loyalty.balanceLoaded ? loyalty.card.spendable : null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: CrystalTheme.header,
        boxShadow: [
          BoxShadow(
            color: CrystalTheme.violet.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: CrystalBloom(size: 160.w, color: CrystalTheme.violetBright),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: CrystalBloom(size: 140.w, color: CrystalTheme.yellow),
          ),
          Positioned(
            right: 18.w,
            top: 14.h,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, t, child) =>
                    Transform.scale(scale: t, child: child),
                child: SvgPicture.asset(CrystalTheme.asset,
                    width: 84.w, height: 84.w),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 80.w),
                  child: Text(
                    l.crystalsEarnedTitle,
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                // Counts up from zero so the reward reads as just landed.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: crystals.toDouble()),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '+${l.crystalsAmount(v.round())}',
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13.sp, color: CrystalTheme.yellow),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        '${l.walletPending} · ${l.walletPendingHint}',
                        style: TextStyle(
                          fontFamily: CrystalTheme.font,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: CrystalTheme.yellow,
                        ),
                      ),
                    ),
                  ],
                ),
                if (balance != null) ...[
                  SizedBox(height: 14.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${l.yourCrystals}: ',
                          style: TextStyle(
                            fontFamily: CrystalTheme.font,
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          _money.format(balance),
                          style: TextStyle(
                            fontFamily: CrystalTheme.font,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
