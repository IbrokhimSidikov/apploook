import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// The "how cashback works" bottom sheet, shared by the profile card and the
/// wallet screen so the two never drift apart.
///
/// Driven by the order types the server actually has configured rather than a
/// hardcoded list - change the programme row and this text follows.
void showLoyaltyInfoSheet(BuildContext context, LoyaltyProvider loyalty) {
  final l10n = AppLocalizations.of(context);
  final program = loyalty.program;
  final rate = program.earnRatePercent;
  final rateLabel =
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

  String nameFor(int id) {
    switch (id) {
      case 1:
        return l10n.inRestaurant;
      case 2:
        return l10n.selfPickup;
      case 3:
        return l10n.delivery;
      case 8:
        return l10n.carhop;
      default:
        return '#$id';
    }
  }

  final eligible = program.eligibleOrderTypeIds;
  final deliveryExcluded = !eligible.contains(3);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4.h,
                width: 40.w,
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              l10n.loyaltyInfoTitle,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14.h),
            _InfoRow(
              icon: Icons.percent_rounded,
              text: '${l10n.walletEarnRateLead} $rateLabel% '
                  '${l10n.walletEarnRateTrail}',
            ),
            SizedBox(height: 14.h),
            Text(
              l10n.loyaltyInfoAppliesTo,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final id in eligible)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.cxFEC700),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 14.sp, color: const Color(0xFF8A6D00)),
                        SizedBox(width: 5.w),
                        Text(
                          nameFor(id),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5C4800),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (deliveryExcluded) ...[
              SizedBox(height: 14.h),
              _InfoRow(
                icon: Icons.delivery_dining_outlined,
                text: l10n.loyaltyInfoNotOnDelivery,
                muted: true,
              ),
            ],
            SizedBox(height: 14.h),
            _InfoRow(
              icon: Icons.shopping_bag_outlined,
              text: l10n.loyaltyInfoSpend,
            ),
            SizedBox(height: 14.h),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: l10n.loyaltyInfoPending,
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoRow({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final colour = muted ? Colors.grey.shade500 : AppColors.cx1B8A4C;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17.sp, color: colour),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: muted ? Colors.grey.shade600 : Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }
}
