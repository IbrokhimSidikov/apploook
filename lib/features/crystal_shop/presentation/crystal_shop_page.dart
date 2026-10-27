import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/l10n/app_localizations.dart';
import '../application/crystal_shop_controller.dart';
import 'crystal_rankings_view.dart';
import 'crystal_shop_view.dart';
import 'crystal_theme.dart';

/// Crystal Shop tab: a violet header holding the customer's crystal balance
/// and a Shop / Rankings switch, with the chosen view underneath.
class CrystalShop extends StatefulWidget {
  const CrystalShop({super.key});

  @override
  State<CrystalShop> createState() => _CrystalShopState();
}

class _CrystalShopState extends State<CrystalShop> {
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<CrystalShopController>();
      controller.loadShop(silent: true);
      controller.loadRankings(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The tab is rebuilt when the shell switches to it; pick up any menu or
    // session change that happened meanwhile without flashing the shimmer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<CrystalShopController>();
      if (controller.shopState == CrystalLoadState.error) {
        controller.loadShop(silent: true);
      }
      if (controller.rankingsState == CrystalLoadState.signedOut &&
          controller.hasSession) {
        controller.loadRankings(silent: true);
      }
    });
  }

  void _select(int index) {
    if (index == _segment) return;
    HapticFeedback.selectionClick();
    setState(() => _segment = index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: CrystalTheme.page,
      body: Column(
        children: [
          _Header(
            segment: _segment,
            onSegment: _select,
            labels: [l.shop, l.rankings],
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _segment == 0
                  ? const CrystalShopView(key: ValueKey('shop'))
                  : const CrystalRankingsView(key: ValueKey('rankings')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.segment,
    required this.onSegment,
    required this.labels,
  });

  final int segment;
  final ValueChanged<int> onSegment;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      child: Container(
        decoration: const BoxDecoration(gradient: CrystalTheme.header),
        child: Stack(
          children: [
            // Soft light blooms for depth.
            Positioned(
              top: -40,
              right: -30,
              child: CrystalBloom(size: 190.w, color: CrystalTheme.violetBright),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: CrystalBloom(size: 170.w, color: const Color(0xFFFEC700)),
            ),
            // A faint oversized crystal peeking from the edge.
            Positioned(
              right: 8.w,
              top: topInset + 8.h,
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(CrystalTheme.asset,
                    width: 120.w, height: 120.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, topInset + 14.h, 20.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crystal Shop',
                              style: TextStyle(
                                fontFamily: CrystalTheme.font,
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l.crystalShopSubtitle,
                              style: TextStyle(
                                fontFamily: CrystalTheme.font,
                                fontSize: 13.sp,
                                height: 1.3,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      const _BalanceChip(),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  _SegmentedControl(
                    index: segment,
                    labels: labels,
                    onChanged: onSegment,
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

/// Glass pill with the customer's crystal balance.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip();

  static final _fmt = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Both come from LoyaltyProvider through the controller, so the chip
    // follows the wallet: shimmer while the summary is on its way, a dash
    // without a session.
    final balance = context.select<CrystalShopController, int?>(
        (c) => c.balance);
    final loading = context.select<CrystalShopController, bool>(
        (c) => c.balanceLoading);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 14.w, 8.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(CrystalTheme.asset, width: 34.w, height: 34.w),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.yourCrystals,
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 9.5.sp,
                      height: 1.2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (loading)
                    Shimmer.fromColors(
                      baseColor: Colors.white.withValues(alpha: 0.35),
                      highlightColor: Colors.white.withValues(alpha: 0.8),
                      child: Container(
                        width: 36.w,
                        height: 14.h,
                        margin: EdgeInsets.only(top: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    )
                  else
                    Text(
                      balance == null ? '—' : _fmt.format(balance),
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-option switch on a glass track; the white thumb slides between them.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final thumbWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: thumbWidth * index,
                top: 0,
                bottom: 0,
                width: thumbWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: CrystalTheme.font,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: i == index
                                  ? CrystalTheme.violetDeep
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
