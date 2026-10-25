import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:apploook/features/crystal_shop/domain/crystal_rank.dart';
import 'package:apploook/features/crystal_shop/presentation/crystal_rank_board.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import 'package:apploook/widgets/loyalty_info_sheet.dart';

/// The crystal wallet: card, balance, and the ledger behind it.
///
/// Every figure shown here comes from the server. The screen deliberately
/// shows pending crystals as their own line rather than folding them into
/// the balance, because pending crystals cannot be spent yet and a single
/// blended number is the fastest way to generate support tickets.
class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  late Future<List<LoyaltyTransaction>> _history;

  @override
  void initState() {
    super.initState();
    // The provider already holds the balance the profile screen fetched -
    // paint it on the first frame and refresh quietly underneath. History is
    // the only thing this screen genuinely has to load, so it starts now and
    // shimmers while in flight.
    final provider = context.read<LoyaltyProvider>();
    _history = provider.fetchHistory();
    provider.refresh(silent: true);
  }

  Future<void> _load() async {
    final provider = context.read<LoyaltyProvider>();
    await provider.refresh(silent: true);
    if (!mounted) return;
    setState(() {
      _history = provider.fetchHistory();
    });
  }

  /// Whole crystals with the unit word declined per language; the ledger
  /// never carries fractions, so there is nothing to format beyond that.
  String _crystals(int value) => _l10n.crystalsAmount(value);

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoyaltyProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _l10n.walletTitle,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.cx0B0B0B,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.cx0B0B0B),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showLoyaltyInfoSheet(context, provider),
          ),
        ],
      ),
      body: !provider.hasSession && provider.sessionKnown
          ? _SignInPrompt(message: _l10n.walletSignInRequired)
          : RefreshIndicator(
              color: AppColors.cxFEC700,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  _CardTile(
                    card: provider.card,
                    amount: _crystals,
                    tierLabel: rankName(_l10n, CrystalRank.forTier(provider.card.tier)),
                    availableLabel: _l10n.walletAvailable,
                    pendingLabel: _l10n.walletPending,
                    pendingHint: _l10n.walletPendingHint,
                    isLoading: !provider.balanceLoaded,
                  ),
                  SizedBox(height: 12.h),
                  _PayInStoreButton(
                    label: _l10n.qrPayTitle,
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/qr-pay');
                      // Crystals may have been spent at the till while the
                      // QR page was up - come back showing the real balance.
                      if (mounted) _load();
                    },
                  ),
                  SizedBox(height: 16.h),
                  _HintTile(text: _l10n.walletEarnHint),
                  SizedBox(height: 24.h),
                  Text(
                    _l10n.walletHistory,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cx0B0B0B,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FutureBuilder<List<LoyaltyTransaction>>(
                    future: _history,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _HistoryShimmer();
                      }
                      final rows = snapshot.data ?? const <LoyaltyTransaction>[];
                      if (rows.isEmpty) {
                        return _EmptyHistory(message: _l10n.walletNoHistory);
                      }
                      return Column(
                        children: [
                          for (final t in rows)
                            _HistoryRow(
                              entry: t,
                              amount: _crystals,
                              label: _labelFor(t),
                              pendingLabel: _l10n.walletPending,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  String _labelFor(LoyaltyTransaction t) {
    switch (t.kind) {
      case LoyaltyEntryKind.earn:
        return _l10n.walletEntryEarned;
      case LoyaltyEntryKind.redeem:
        return _l10n.walletEntrySpent;
      case LoyaltyEntryKind.reversal:
        return _l10n.walletEntryCancelled;
      case LoyaltyEntryKind.refund:
        return _l10n.walletEntryReturned;
      case LoyaltyEntryKind.expiry:
        return _l10n.walletEntryExpired;
      case LoyaltyEntryKind.conversion:
        return _l10n.walletEntryConverted;
      case LoyaltyEntryKind.adjustment:
        return _l10n.walletEntryAdjusted;
    }
  }
}

class _CardTile extends StatelessWidget {
  final LoyaltyCard card;
  final String Function(int) amount;

  /// Which crystal price list the customer buys from. Shown on the card so a
  /// customer on a better level can see why their prices differ.
  final String tierLabel;
  final String availableLabel;
  final String pendingLabel;

  /// Why pending points are not spendable yet: they mature at the next
  /// local midnight, not after a fixed delay.
  final String pendingHint;
  final bool isLoading;

  const _CardTile({
    required this.card,
    required this.amount,
    required this.tierLabel,
    required this.availableLabel,
    required this.pendingLabel,
    required this.pendingHint,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Same violet board as the profile crystal card: header gradient, two
    // soft colour blooms and a faint oversized crystal behind the figures.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: CrystalTheme.header,
        boxShadow: [
          BoxShadow(
            color: CrystalTheme.violet.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: CrystalBloom(size: 170.w, color: CrystalTheme.violetBright),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: CrystalBloom(size: 150.w, color: CrystalTheme.yellow),
          ),
          Positioned(
            right: 24.w,
            bottom: -16.h,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: SvgPicture.asset(CrystalTheme.asset,
                    width: 110.w, height: 110.w),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      availableLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (!isLoading) _TierPill(label: tierLabel),
                    const Spacer(),
                    SvgPicture.asset(CrystalTheme.asset, width: 22.w, height: 22.w),
                  ],
                ),
                SizedBox(height: 6.h),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: _DarkShimmerBar(width: 140.w, height: 26.h),
                  )
                else
                  Text(
                    amount(card.spendable),
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (card.pendingBalance > 0) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14.sp, color: Colors.white.withOpacity(0.6)),
                      SizedBox(width: 6.w),
                      Text(
                        '$pendingLabel: ${amount(card.pendingBalance)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: EdgeInsets.only(left: 20.w),
                    child: Text(
                      pendingHint,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Text(
                  card.number.isEmpty ? '—' : card.number,
                  style: TextStyle(
                    fontSize: 14.sp,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
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

class _PayInStoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PayInStoreButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cxFEC700,
          foregroundColor: AppColors.cx0B0B0B,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        onPressed: onPressed,
        icon: Icon(Icons.qr_code_2_rounded, size: 22.sp),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
        ),
      ),
    );
  }
}

/// The customer's price level, as a small chip in the card's header row.
class _TierPill extends StatelessWidget {
  final String label;
  const _TierPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: CrystalTheme.violetBright.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: CrystalTheme.violetBright.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// One-line reminder of how crystals are earned. There is no rate to quote
/// any more - every product carries its own crystal figure - so this is a
/// plain sentence rather than a number.
class _HintTile extends StatelessWidget {
  final String text;
  const _HintTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          SvgPicture.asset(CrystalTheme.asset, width: 18.w, height: 18.w),
          SizedBox(width: 10.w),
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

class _HistoryRow extends StatelessWidget {
  final LoyaltyTransaction entry;
  final String Function(int) amount;
  final String label;
  final String pendingLabel;

  const _HistoryRow({
    required this.entry,
    required this.amount,
    required this.label,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    // A reversed row is history, not a live balance change - grey it out so it
    // reads as "this was undone" rather than as another movement.
    final muted = entry.isReversed;
    final colour = muted
        ? Colors.grey
        : (isCredit ? AppColors.cx1B8A4C : AppColors.cx0B0B0B);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: colour.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFor(entry),
              size: 18.sp,
              color: colour,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: muted ? Colors.grey : AppColors.cx0B0B0B,
                    decoration:
                        muted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  [
                    if (entry.orderId != null) '#${entry.orderId}',
                    if (entry.createdAt != null)
                      DateFormat('dd.MM.yyyy HH:mm').format(entry.createdAt!),
                  ].join('  ·  '),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '−'}${amount(entry.amount.abs())}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: colour,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (entry.isPending)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    pendingLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LoyaltyTransaction t) {
    switch (t.kind) {
      case LoyaltyEntryKind.earn:
        return Icons.savings_rounded;
      case LoyaltyEntryKind.redeem:
        return Icons.shopping_bag_rounded;
      case LoyaltyEntryKind.reversal:
        return Icons.undo_rounded;
      case LoyaltyEntryKind.refund:
        return Icons.replay_rounded;
      case LoyaltyEntryKind.expiry:
        return Icons.hourglass_disabled_rounded;
      case LoyaltyEntryKind.conversion:
        return Icons.swap_horiz_rounded;
      case LoyaltyEntryKind.adjustment:
        return Icons.tune_rounded;
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  final String message;
  const _EmptyHistory({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 34.sp, color: Colors.grey.shade400),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  final String message;
  const _SignInPrompt({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cxFEC700,
                foregroundColor: AppColors.cx0B0B0B,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
              ),
              onPressed: () => Navigator.pushNamed(context, '/signin'),
              child: Text(
                AppLocalizations.of(context).signIn,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder bar for a figure on its way, tuned for the dark card.
class _DarkShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const _DarkShimmerBar({required this.width, required this.height});

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

/// The history list while it loads: rows the same shape as the real ones, so
/// nothing jumps when the data lands.
class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(120.w, 12.h),
                      SizedBox(height: 6.h),
                      bar(80.w, 10.h),
                    ],
                  ),
                ),
                bar(56.w, 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
