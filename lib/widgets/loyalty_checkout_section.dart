import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// The "spend your cashback" block on the checkout screen.
///
/// It renders nothing at all unless the customer has a session, a usable
/// balance and a basket the points can apply to - an always-visible but
/// permanently disabled control is worse than no control.
///
/// Every number shown comes from `/loyalty/quote`. The widget does no
/// arithmetic of its own, so what the customer sees is exactly what the server
/// will reserve.
class LoyaltyCheckoutSection extends StatelessWidget {
  /// Food subtotal in soum, excluding delivery.
  final int subtotal;

  /// Delivery fee in soum.
  final int deliveryFee;

  /// Whether points may be spent on this order.
  ///
  /// False for card payments: the RahmatPay invoice carries fiscal (OFD) line
  /// items that must sum to the charged amount, so discounting the charge
  /// without a matching OFD line would produce an invalid receipt. Earning is
  /// unaffected and stays on for every payment method.
  final bool allowRedeem;

  const LoyaltyCheckoutSection({
    super.key,
    required this.subtotal,
    this.deliveryFee = 0,
    this.allowRedeem = true,
  });

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyProvider>();
    final l10n = AppLocalizations.of(context);

    // The provider establishes the session itself (beginCheckout calls
    // ensureSession), so there is nothing for the customer to tap; the block
    // simply appears once the quote arrives.
    if (!loyalty.hasSession) return const SizedBox.shrink();

    final quote = loyalty.quote;
    final earn = loyalty.projectedEarn;

    // Nothing to spend, but there is still cashback coming - tell them that
    // much, since it is the whole reason the programme exists.
    if (quote != null && (!allowRedeem || !loyalty.canOfferCashback)) {
      if (earn <= 0) return const SizedBox.shrink();
      return _EarnOnlyNote(
        text: '${l10n.checkoutYouWillEarn} '
            '${_money.format(earn)} ${l10n.currency}',
      );
    }

    if (quote == null) return const SizedBox.shrink();

    final step = loyalty.program.redeemRounding.clamp(1, 1000000);
    final maxPoints = loyalty.maxRedeemable;
    final divisions = (maxPoints / step).floor().clamp(1, 1000);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  size: 18.sp, color: AppColors.cxFEC700),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.checkoutUseCashback,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_money.format(quote.spendable)} ${l10n.currency} '
                      '${l10n.checkoutCashbackAvailable}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: loyalty.useCashback,
                activeThumbColor: AppColors.cx1B8A4C,
                onChanged: (v) => loyalty.setUseCashback(v),
              ),
            ],
          ),
          if (loyalty.useCashback) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: loyalty.requestedPoints
                        .toDouble()
                        .clamp(0, maxPoints.toDouble()),
                    min: 0,
                    max: maxPoints.toDouble(),
                    divisions: divisions,
                    activeColor: AppColors.cx1B8A4C,
                    label: _money.format(loyalty.requestedPoints),
                    onChanged: (v) => loyalty.requestPoints(v.round()),
                  ),
                ),
                TextButton(
                  onPressed: () => loyalty.requestPoints(maxPoints),
                  child: Text(
                    l10n.checkoutCashbackAll,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cx1B8A4C,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.checkoutCashbackApplied,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                ),
                loyalty.isQuoting
                    ? SizedBox(
                        height: 14.h,
                        width: 14.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '− ${_money.format(loyalty.appliedPoints)} ${l10n.currency}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cx1B8A4C,
                        ),
                      ),
              ],
            ),
          ],
          if (earn > 0) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.savings_rounded,
                    size: 13.sp, color: Colors.grey.shade500),
                SizedBox(width: 6.w),
                Text(
                  '${l10n.checkoutYouWillEarn} '
                  '${_money.format(earn)} ${l10n.currency}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EarnOnlyNote extends StatelessWidget {
  final String text;
  const _EarnOnlyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_rounded, size: 16.sp, color: AppColors.cx1B8A4C),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
