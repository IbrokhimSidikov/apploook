import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// Compact crystal pill for the home app bar: crystal icon plus the spendable
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
        borderRadius: BorderRadius.circular(20.r),
        onTap: () {
          if (unavailable) {
            context.read<LoyaltyProvider>().refresh();
          } else {
            Navigator.pushNamed(context, '/wallet');
          }
        },
        // Same lilac pill as the crystal badge on the menu product cards, so
        // the balance and the per-product reward read as one family.
        child: Container(
          // Tighter vertical padding than the 24 px icon would suggest, so
          // the bigger crystal fits a pill of the same height as before.
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 12.w, 4.h),
          decoration: BoxDecoration(
            color: CrystalTheme.lilac,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFDCD0FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(CrystalTheme.asset, width: 24.w, height: 24.w),
              SizedBox(width: 5.w),
              if (label == null)
                Shimmer.fromColors(
                  baseColor: CrystalTheme.lilacText.withValues(alpha: 0.15),
                  highlightColor: CrystalTheme.lilacText.withValues(alpha: 0.35),
                  child: Container(
                    width: 36.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: CrystalTheme.lilacText,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    color: CrystalTheme.lilacText,
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
