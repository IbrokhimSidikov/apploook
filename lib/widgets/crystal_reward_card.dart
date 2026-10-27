import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/crystal_shop/presentation/crystal_theme.dart';
import '../l10n/app_localizations.dart';


/// "Buy this and earn +N crystals" promo board for the product details page.
///
/// Soft lilac card with a faceted crystal on the left and a two-line
/// message on the right; the crystal count line is the loud one.
class CrystalRewardCard extends StatelessWidget {
  const CrystalRewardCard({super.key, required this.crystals});

  final int crystals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F2FF), CrystalTheme.lilac],
        ),
        border: Border.all(color: const Color(0xFFDCD0FF)),
        boxShadow: [
          BoxShadow(
            color: CrystalTheme.violetBright.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glow behind the crystal so it reads as lit, not pasted on.
          Container(
            width: 56.w,
            height: 56.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: SvgPicture.asset(CrystalTheme.asset, width: 54.w, height: 54.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.crystalRewardIntro,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: CrystalTheme.ink.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l.crystalRewardAmount(crystals),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: CrystalTheme.lilacText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact pill form of [CrystalRewardCard] for cart rows: crystal icon
/// plus "+N crystals" on one line.
class CrystalRewardChip extends StatelessWidget {
  const CrystalRewardChip({super.key, required this.crystals});

  final int crystals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 3.h, 9.w, 3.h),
      decoration: BoxDecoration(
        color: CrystalTheme.lilac,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFDCD0FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(CrystalTheme.asset, width: 19.w, height: 19.w),
          SizedBox(width: 5.w),
          Text(
            l.crystalRewardCompact(crystals),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: CrystalTheme.lilacText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "+N" crystal badge shown beside the price tag on a menu card.
/// Same height as the price pill so the two read as one row.
class CrystalPointsBadge extends StatelessWidget {
  const CrystalPointsBadge({super.key, required this.crystals});

  final int crystals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(7.w, 5.h, 9.w, 5.h),
      decoration: BoxDecoration(
        color: CrystalTheme.lilac,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFDCD0FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(CrystalTheme.asset, width: 18.w, height: 18.w),
          SizedBox(width: 3.w),
          Text(
            '+$crystals',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: CrystalTheme.lilacText,
            ),
          ),
        ],
      ),
    );
  }
}
