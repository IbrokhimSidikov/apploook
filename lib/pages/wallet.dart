import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import 'package:apploook/widgets/loyalty_info_sheet.dart';

/// The cashback wallet: card, balance, and the ledger behind it.
///
/// Every figure shown here comes from the server. The screen deliberately
/// shows pending cashback as its own line rather than folding it into the
/// balance, because pending points cannot be spent yet and a single blended
/// number is the fastest way to generate support tickets.
class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  static final _money = NumberFormat('#,##0', 'en_US');

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

  String _soum(int value) => '${_money.format(value)} ${_l10n.currency}';

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
                    program: provider.program,
                    money: _soum,
                    availableLabel: _l10n.walletAvailable,
                    pendingLabel: _l10n.walletPending,
                    isLoading: !provider.balanceLoaded,
                  ),
                  SizedBox(height: 16.h),
                  _RateStrip(
                    text: _l10n.walletEarnRateLead,
                    rate: provider.program.earnRatePercent,
                    suffix: _l10n.walletEarnRateTrail,
                  ),
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
                              money: _soum,
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
      case LoyaltyEntryKind.adjustment:
        return _l10n.walletEntryAdjusted;
    }
  }
}

class _CardTile extends StatelessWidget {
  final LoyaltyCard card;
  final LoyaltyProgram program;
  final String Function(int) money;
  final String availableLabel;
  final String pendingLabel;
  final bool isLoading;

  const _CardTile({
    required this.card,
    required this.program,
    required this.money,
    required this.availableLabel,
    required this.pendingLabel,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2E2A16)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Icon(Icons.card_giftcard_rounded,
                  size: 20.sp, color: AppColors.cxFEC700),
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
              money(card.spendable),
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
                  '$pendingLabel: ${money(card.pendingBalance)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
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
    );
  }
}

class _RateStrip extends StatelessWidget {
  final String text;
  final double rate;
  final String suffix;

  const _RateStrip({
    required this.text,
    required this.rate,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.percent_rounded, size: 18.sp, color: AppColors.cx1B8A4C),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '$text $formatted% $suffix',
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
  final String Function(int) money;
  final String label;
  final String pendingLabel;

  const _HistoryRow({
    required this.entry,
    required this.money,
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
                '${isCredit ? '+' : '−'}${money(entry.amount.abs())}',
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
