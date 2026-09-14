import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// Compact cashback pill for the home app bar: coin icon plus the spendable
/// balance. Tapping opens the wallet.
///
/// Mirrors the visibility rules of [LoyaltyProfileCard]: hidden only once it
/// is known there is no customer session, shimmering while the balance is
/// still on its way, so the header never pops a figure in late.
class CashbackBadge extends StatelessWidget {
  const CashbackBadge({super.key});

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyProvider>();

    final bool known = loyalty.sessionKnown;
    if (known && !loyalty.hasSession && !loyalty.needsActivation) {
      return const SizedBox.shrink();
    }

    final bool loading = !known ||
        (loyalty.hasSession ? !loyalty.balanceLoaded : loyalty.isActivating);
    final bool unavailable =
        known && !loyalty.hasSession && !loyalty.isActivating;

    final label = loading
        ? null
        : unavailable
            ? '—'
            : _money.format(loyalty.card.spendable);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: () {
          if (unavailable) {
            context.read<LoyaltyProvider>().refresh();
          } else {
            Navigator.pushNamed(context, '/wallet');
          }
        },
        // Same yellow chip as the Reorder button in this app bar, so the two
        // read as one family of header actions.
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: AppColors.cxFEC700,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: AppColors.cx0B0B0B,
                size: 18.w,
              ),
              SizedBox(width: 6.w),
              if (label == null)
                Shimmer.fromColors(
                  baseColor: AppColors.cx0B0B0B.withValues(alpha: 0.15),
                  highlightColor: AppColors.cx0B0B0B.withValues(alpha: 0.35),
                  child: Container(
                    width: 36.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: AppColors.cx0B0B0B,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.cx0B0B0B,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
