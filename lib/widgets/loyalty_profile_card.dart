import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/providers/loyalty_provider.dart';

/// The customer's cashback card on the profile screen.
///
/// The card is created server-side the moment the OTP is accepted, so this is
/// visible from a customer's very first sign-in - showing a real card with a
/// zero balance rather than an empty state, which is what makes the programme
/// feel active from day one.
class LoyaltyProfileCard extends StatelessWidget {
  const LoyaltyProfileCard({super.key});

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyProvider>();
    final l10n = AppLocalizations.of(context);

    // Not signed in to the app at all: nothing to show.
    if (!loyalty.hasSession && !loyalty.needsActivation) {
      return const SizedBox.shrink();
    }

    // Signed in but the session is still being established (the provider
    // resumes it automatically). Show the same card in a quiet state rather
    // than a button - the customer has nothing to do.
    final activating = !loyalty.hasSession;
    final card = loyalty.card;
    final rate = loyalty.program.earnRatePercent;
    final rateLabel =
        rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

    return GestureDetector(
      onTap: activating ? null : () => Navigator.pushNamed(context, '/wallet'),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2E2A16)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard_rounded,
                    size: 15.sp, color: AppColors.cxFEC700),
                SizedBox(width: 6.w),
                Text(
                  l10n.walletTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppColors.cxFEC700,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '$rateLabel%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cx0B0B0B,
                    ),
                  ),
                ),
                const Spacer(),
                // Generous hit target: the icon itself is far too small to be
                // a comfortable tap on a card that is also tappable.
                InkWell(
                  onTap: () => _showInfoSheet(context, loyalty),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(6.r),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (activating)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cxFEC700,
                      ),
                    ),
                  )
                else
                  Text(
                    _money.format(card.spendable),
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                SizedBox(width: 5.w),
                Text(
                  l10n.currency,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                if (card.pendingBalance > 0) ...[
                  Icon(Icons.schedule_rounded,
                      size: 12.sp, color: AppColors.cxFEC700),
                  SizedBox(width: 4.w),
                  Text(
                    '${l10n.walletPending} '
                    '${_money.format(card.pendingBalance)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.cxFEC700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    card.number.isEmpty ? '' : card.number,
                    style: TextStyle(
                      fontSize: 11.sp,
                      letterSpacing: 1.4,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 16.sp, color: Colors.white.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Explains the programme, driven by the order types the server actually
  /// has configured rather than a hardcoded list.
  void _showInfoSheet(BuildContext context, LoyaltyProvider loyalty) {
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 7.h),
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
