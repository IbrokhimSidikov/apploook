import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';

const _kCrystalAsset = 'images/crystal.svg';
const _kAmber = Color(0xFFE8590C);
const _kInk = Color(0xFF3D2E00);

/// "Buy this and earn +N crystals" promo board for the product details page.
///
/// Soft yellow card with a faceted crystal on the left and a two-line
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
          colors: [Color(0xFFFFF6D6), Color(0xFFFFE9A8)],
        ),
        border: Border.all(color: const Color(0xFFFFD666)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFEC700).withValues(alpha: 0.22),
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
            child: SvgPicture.asset(_kCrystalAsset, width: 44.w, height: 44.w),
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
                    color: _kInk.withValues(alpha: 0.75),
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
                    color: _kInk,
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
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(_kCrystalAsset, width: 14.w, height: 14.w),
          SizedBox(width: 5.w),
          Text(
            l.crystalRewardCompact(crystals),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: _kAmber,
            ),
          ),
        ],
      ),
    );
  }
}
