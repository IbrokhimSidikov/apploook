import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// The crystal summary block on the checkout screen.
///
/// There is nothing to dial in here: which lines are paid with crystals was
/// decided in the cart. This block tells the customer what that decision
/// means for this order - crystals leaving the card, soum still to pay, and
/// crystals coming back - and, when the server refused the basket as
/// configured, why and what to change.
///
/// Every number shown comes from `/loyalty/quote`. The widget does no
/// arithmetic of its own, so what the customer sees is exactly what the
/// server will reserve.
class LoyaltyCheckoutSection extends StatelessWidget {
  const LoyaltyCheckoutSection({super.key});

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
    if (quote == null) return const SizedBox.shrink();

    final spend = loyalty.appliedCrystals;
    final earn = loyalty.projectedEarn;
    final blocked = loyalty.orderBlocked;

    // Nothing in play: no crystal lines, nothing earned. Stay out of the way.
    if (spend <= 0 && earn <= 0 && !blocked) return const SizedBox.shrink();

    String? warning;
    if (quote.blockedReason == 'insufficient_crystals') {
      warning = l10n.checkoutNotEnoughCrystals(loyalty.shortfall);
    } else if (quote.blockedReason == 'line_problems') {
      warning = l10n.checkoutCrystalLineProblem;
    } else if (blocked) {
      warning = l10n.checkoutCashbackChanged;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: blocked ? const Color(0xFFE57373) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(CrystalTheme.asset, width: 24.w, height: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.walletTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_money.format(quote.spendable)} ${l10n.crystalWord(quote.spendable)} '
                '${l10n.checkoutCashbackAvailable}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              if (loyalty.isQuoting) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  height: 12.h,
                  width: 12.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          if (spend > 0) ...[
            SizedBox(height: 8.h),
            _Line(
              label: l10n.checkoutCrystalsToSpend,
              value: '− ${l10n.crystalsAmount(spend)}',
              valueColor: CrystalTheme.violetDeep,
            ),
            SizedBox(height: 4.h),
            _Line(
              label: l10n.checkoutToPay,
              value: '${_money.format(quote.payable)} ${l10n.currency}',
              valueColor: AppColors.cx0B0B0B,
            ),
          ],
          if (earn > 0) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 13.sp, color: Colors.grey.shade500),
                SizedBox(width: 6.w),
                Text(
                  '${l10n.checkoutYouWillEarn} ${l10n.crystalsAmount(earn)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          if (warning != null) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 15.sp, color: const Color(0xFFC62828)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    warning,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFC62828),
                      fontWeight: FontWeight.w600,
                    ),
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

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _Line({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
