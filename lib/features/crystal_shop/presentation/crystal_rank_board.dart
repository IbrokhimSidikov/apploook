import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import '../domain/crystal_rank.dart';
import 'crystal_theme.dart';

final _date = DateFormat('dd.MM.yyyy');

String rankName(AppLocalizations l, CrystalRank rank) => switch (rank) {
      CrystalRank.bronze => l.rankBronze,
      CrystalRank.gold => l.rankGold,
      CrystalRank.diamond => l.rankDiamond,
    };

/// Top of the shop tab: the customer's level (bronze, gold, diamond) from
/// `/loyalty/tier`, the three levels on a track, how many qualifying orders
/// the next one needs, and when the current one lapses without new orders.
class CrystalRankBoard extends StatelessWidget {
  const CrystalRankBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loyalty = context.watch<LoyaltyProvider>();
    final loading = !loyalty.sessionKnown ||
        (loyalty.hasSession &&
            !loyalty.balanceLoaded &&
            loyalty.error == null);
    final known = loyalty.hasSession && loyalty.balanceLoaded;
    final rank = known ? CrystalRank.forTier(loyalty.levelTier) : null;
    final status = known ? loyalty.tierStatus : null;
    final accent = rank ?? CrystalRank.bronze;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: CrystalTheme.border),
          // White card washed with the current level's colour at the top.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rank == null
                  ? Colors.white
                  : accent.colors.first.withValues(alpha: 0.28),
              Colors.white,
            ],
            stops: const [0, 0.7],
          ),
          boxShadow: [
            BoxShadow(
              color: CrystalTheme.violet.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Medal(rank: accent, size: 54.w, dimmed: rank == null),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.rankBoardTitle,
                        style: TextStyle(
                          fontFamily: CrystalTheme.font,
                          fontSize: 12.sp,
                          color: CrystalTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      if (rank != null)
                        Text(
                          rankName(l, rank),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: CrystalTheme.font,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: rank.ink,
                          ),
                        )
                      else if (loading)
                        _ShimmerLine(width: 130.w, height: 20.h)
                      else
                        Text(
                          l.rankSignIn,
                          style: TextStyle(
                            fontFamily: CrystalTheme.font,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: CrystalTheme.ink,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _RankTrack(current: rank, next: status?.next),
            if (rank != null) ...[
              SizedBox(height: 14.h),
              _Hints(rank: rank, status: status),
            ],
          ],
        ),
      ),
    );
  }
}

/// The three medals joined by bars: full behind the current level, and the
/// bar towards the next level filled by the qualifying orders so far.
class _RankTrack extends StatelessWidget {
  const _RankTrack({required this.current, required this.next});

  final CrystalRank? current;
  final LoyaltyTierNext? next;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const ranks = CrystalRank.values;
    final nextRank = next == null ? null : CrystalRank.forTier(next!.tier);

    final children = <Widget>[];
    for (var i = 0; i < ranks.length; i++) {
      final rank = ranks[i];
      final reached = current != null && rank.index <= current!.index;
      children.add(_Step(
        rank: rank,
        label: rankName(l, rank),
        reached: reached,
        isCurrent: rank == current,
      ));
      if (i + 1 < ranks.length) {
        final upcoming = ranks[i + 1];
        final double fill;
        if (current != null && upcoming.index <= current!.index) {
          fill = 1;
        } else if (rank == current && upcoming == nextRank) {
          fill = next!.progress;
        } else {
          fill = 0;
        }
        children.add(Expanded(
          child: Padding(
            // Centred on the 36.w medals, whose tops align with the bar's row.
            padding: EdgeInsets.only(top: 18.w - 3.h),
            child: _Bar(fill: fill, colors: upcoming.colors),
          ),
        ));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.rank,
    required this.label,
    required this.reached,
    required this.isCurrent,
  });

  final CrystalRank rank;
  final String label;
  final bool reached;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: Column(
        children: [
          AnimatedScale(
            scale: isCurrent ? 1.12 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: _Medal(rank: rank, size: 36.w, dimmed: !reached),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 11.5.sp,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: reached ? rank.ink : CrystalTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fill, required this.colors});

  final double fill;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBF4),
        borderRadius: BorderRadius.circular(3.r),
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fill),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round medal in the level's metal, greyed out until it is reached.
class _Medal extends StatelessWidget {
  const _Medal({required this.rank, required this.size, this.dimmed = false});

  final CrystalRank rank;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: dimmed
            ? const LinearGradient(
                colors: [Color(0xFFF1EFF6), Color(0xFFDCD8E6)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: rank.colors,
              ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: dimmed
            ? null
            : [
                BoxShadow(
                  color: rank.colors.last.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        rank.icon,
        size: size * 0.52,
        color: dimmed ? const Color(0xFFB4AFC4) : Colors.white,
      ),
    );
  }
}

/// What to do next: the orders still needed for the next level (or the
/// top-level note), when the current level lapses, and the window the
/// orders are counted over. Without a tier status (request failed) only the
/// top-level note can be said for sure.
class _Hints extends StatelessWidget {
  const _Hints({required this.rank, required this.status});

  final CrystalRank rank;
  final LoyaltyTierStatus? status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final next = status?.next;
    final downgrade = status?.downgrade;
    final windowDays = status?.windowDays ?? 0;

    final String? headline = next != null
        ? l.rankToNextOrders(next.remaining, next.minCheckAmount,
            rankName(l, CrystalRank.forTier(next.tier)))
        : rank.next == null
            ? l.rankTop
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline != null)
          _HintRow(
            icon: next == null
                ? Icons.auto_awesome_rounded
                : Icons.trending_up_rounded,
            text: headline,
            filled: true,
          ),
        if (downgrade != null) ...[
          if (headline != null) SizedBox(height: 8.h),
          _HintRow(
            icon: Icons.schedule_rounded,
            text: l.rankKeepUntil(_date.format(downgrade.on), rankName(l, rank)),
          ),
        ],
        if (windowDays > 0) ...[
          SizedBox(height: 10.h),
          Text(
            l.rankWindowHint(windowDays),
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 11.sp,
              color: CrystalTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// One hint line: a lilac pill for the main call to action, a plain row
/// for secondary notes.
class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text, this.filled = false});

  final IconData icon;
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = filled ? CrystalTheme.lilacText : CrystalTheme.textSecondary;
    return Container(
      width: double.infinity,
      padding: filled
          ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h)
          : EdgeInsets.symmetric(horizontal: 2.w),
      decoration: filled
          ? BoxDecoration(
              color: CrystalTheme.lilac,
              borderRadius: BorderRadius.circular(14.r),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: filled ? 12.5.sp : 12.sp,
                fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                height: 1.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEBF4),
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
        ),
      ),
    );
  }
}
