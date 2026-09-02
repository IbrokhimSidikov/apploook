import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import 'package:apploook/widgets/loyalty_info_sheet.dart';

/// The customer's cashback card on the profile screen.
///
/// The board itself renders on the first frame, every time - only the figures
/// wait for the network, behind a shimmer. Painting the frame instantly and
/// letting numbers arrive is what makes the screen feel fast; it also avoids
/// the earlier trap of showing a confident-looking 0 that really meant
/// "not fetched yet".
class LoyaltyProfileCard extends StatelessWidget {
  const LoyaltyProfileCard({super.key});

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyProvider>();
    final l10n = AppLocalizations.of(context);

    // Hide only when it is KNOWN there is no signed-in customer. Before the
    // bootstrap answers - a cold-start window of milliseconds - render the
    // board shimmering rather than nothing: returning shrink here is exactly
    // the blank gap that used to flash before the card popped in.
    final bool known = loyalty.sessionKnown;
    if (known && !loyalty.hasSession && !loyalty.needsActivation) {
      return const SizedBox.shrink();
    }

    // Figures are trustworthy only once a summary has arrived. While the
    // fetch (or the automatic session resume) is in flight, shimmer; if the
    // resume failed outright, show a dash and let a tap retry.
    final bool loading = !known ||
        (loyalty.hasSession ? !loyalty.balanceLoaded : loyalty.isActivating);
    final bool unavailable =
        known && !loyalty.hasSession && !loyalty.isActivating;

    final card = loyalty.card;
    final rate = loyalty.program.earnRatePercent;
    final rateLabel =
        rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

    return GestureDetector(
      onTap: () {
        if (unavailable) {
          // The automatic resume did not get a session - retry it.
          context.read<LoyaltyProvider>().refresh();
        } else {
          Navigator.pushNamed(context, '/wallet');
        }
      },
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
                InkWell(
                  onTap: () => showLoyaltyInfoSheet(context, loyalty),
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
            SizedBox(height: 2.h),
            if (loading)
              _ShimmerBar(width: 120.w, height: 24.h)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    unavailable ? '—' : _money.format(card.spendable),
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    unavailable ? '' : l10n.currency,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 8.h),
            if (loading)
              _ShimmerBar(width: 90.w, height: 11.h)
            else
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
                      card.number,
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

}

/// A placeholder bar for a figure still on its way, tuned for the dark card.
class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.12),
      highlightColor: Colors.white.withOpacity(0.35),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
