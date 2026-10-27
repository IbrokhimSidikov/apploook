import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/l10n/app_localizations.dart';
import '../application/crystal_shop_controller.dart';
import '../domain/crystal_shop_models.dart';
import 'crystal_theme.dart';

final _fmt = NumberFormat('#,##0', 'en_US');

/// Global leaderboard of crystal collectors: a podium for the top three,
/// then the rest as a list. Names only.
class CrystalRankingsView extends StatelessWidget {
  const CrystalRankingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<CrystalShopController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final entries = controller.rankings;
    final me = controller.myRank;
    final meInList = entries.any((e) => e.isMe);

    return RefreshIndicator(
      color: CrystalTheme.violet,
      onRefresh: () => controller.loadRankings(silent: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 6.h),
              child: Text(
                l.topCollectors,
                style: TextStyle(
                  fontFamily: CrystalTheme.font,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: CrystalTheme.ink,
                ),
              ),
            ),
          ),
          ..._buildBody(context, controller, entries),
          if (me != null && !meInList)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                child: _MyRankCard(entry: me),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 20.h)),
        ],
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    CrystalShopController controller,
    List<CrystalRankingEntry> entries,
  ) {
    final l = AppLocalizations.of(context);

    switch (controller.rankingsState) {
      case CrystalLoadState.idle:
      case CrystalLoadState.loading:
        return [const _ShimmerList()];
      case CrystalLoadState.signedOut:
        return [
          SliverToBoxAdapter(
            child: _Empty(
              message: l.walletSignInRequired,
              action: l.signIn,
              onAction: () => Navigator.pushNamed(context, '/signin'),
            ),
          ),
        ];
      case CrystalLoadState.error:
        return [
          SliverToBoxAdapter(
            child: _Empty(
              message: l.rankingsEmpty,
              action: l.retry,
              onAction: controller.loadRankings,
            ),
          ),
        ];
      case CrystalLoadState.ready:
        if (entries.isEmpty) {
          return [SliverToBoxAdapter(child: _Empty(message: l.rankingsEmpty))];
        }
        final podium = entries.take(3).toList();
        final rest = entries.skip(3).toList();
        return [
          SliverToBoxAdapter(child: _Podium(entries: podium)),
          if (rest.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: CrystalTheme.card,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(color: CrystalTheme.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < rest.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 64.w,
                            color: const Color(0xFFF2F0F8),
                          ),
                        _RankRow(entry: rest[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ];
    }
  }
}

// ── Podium ──────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<CrystalRankingEntry> entries;

  CrystalRankingEntry? _at(int rank) =>
      entries.length >= rank ? entries[rank - 1] : null;

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 22.h, 12.w, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF3EFFC)],
          ),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: CrystalTheme.border),
          boxShadow: [
            BoxShadow(
              color: CrystalTheme.violet.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumSpot(entry: second, place: 2, height: 64.h),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _PodiumSpot(entry: first, place: 1, height: 92.h),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _PodiumSpot(entry: third, place: 3, height: 48.h),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.place,
    required this.height,
  });

  final CrystalRankingEntry? entry;
  final int place;
  final double height;

  static const _medal = {
    1: [Color(0xFFFFE27A), Color(0xFFF4B400)],
    2: [Color(0xFFE6E9F2), Color(0xFFB9C0D0)],
    3: [Color(0xFFF6C9A5), Color(0xFFD08A4F)],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = _medal[place]!;
    final e = entry;
    final avatarSize = place == 1 ? 64.w : 52.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (place == 1)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Icon(Icons.emoji_events_rounded,
                size: 26.sp, color: const Color(0xFFF4B400)),
          ),
        Container(
          width: avatarSize + 6,
          height: avatarSize + 6,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _Avatar(name: e?.name ?? '', size: avatarSize),
        ),
        SizedBox(height: 8.h),
        Text(
          e == null ? '—' : (e.isMe ? '${e.name} · ${l.you}' : e.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: CrystalTheme.font,
            fontSize: place == 1 ? 14.sp : 12.5.sp,
            fontWeight: FontWeight.w700,
            color: CrystalTheme.ink,
          ),
        ),
        SizedBox(height: 2.h),
        if (e != null) _CrystalCount(amount: e.crystals, size: 12.sp),
        SizedBox(height: 10.h),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.first, colors.last.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
          ),
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 8.h),
          child: Text(
            '$place',
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── List rows ───────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final CrystalRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      color: entry.isMe ? const Color(0xFFFFF8DB) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: CrystalTheme.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _Avatar(name: entry.name, size: 36.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: CrystalTheme.font,
                      fontSize: 14.sp,
                      fontWeight: entry.isMe ? FontWeight.w700 : FontWeight.w500,
                      color: CrystalTheme.ink,
                    ),
                  ),
                ),
                if (entry.isMe) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: CrystalTheme.yellow,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      l.you,
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: CrystalTheme.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _CrystalCount(amount: entry.crystals, size: 13.sp),
        ],
      ),
    );
  }
}

/// Sticky "your rank" card for a customer outside the top list.
class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry});

  final CrystalRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: CrystalTheme.header,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: CrystalTheme.violet.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.yourRank,
                style: TextStyle(
                  fontFamily: CrystalTheme.font,
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontFamily: CrystalTheme.font,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          _Avatar(name: entry.name, size: 40.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: CrystalTheme.font,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _CrystalCount(amount: entry.crystals, size: 14.sp, onDark: true),
        ],
      ),
    );
  }
}

// ── Atoms ───────────────────────────────────────────────────────────────────

/// Initials on a gradient picked from the name, so the same person always
/// gets the same colour without any photo.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  static const _palettes = [
    [Color(0xFF6B4DE6), Color(0xFF9B7BFF)],
    [Color(0xFFE8590C), Color(0xFFFFA94D)],
    [Color(0xFF0CA678), Color(0xFF63E6BE)],
    [Color(0xFF1C7ED6), Color(0xFF74C0FC)],
    [Color(0xFFD6336C), Color(0xFFFF8CC6)],
    [Color(0xFFF59F00), Color(0xFFFFE066)],
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[name.hashCode.abs() % _palettes.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: CrystalTheme.font,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CrystalCount extends StatelessWidget {
  const _CrystalCount({
    required this.amount,
    required this.size,
    this.onDark = false,
  });

  final int amount;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(CrystalTheme.asset, width: size * 1.35, height: size * 1.35),
        SizedBox(width: 4.w),
        Text(
          _fmt.format(amount),
          style: TextStyle(
            fontFamily: CrystalTheme.font,
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: onDark ? Colors.white : CrystalTheme.lilacText,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFEDEBF4),
              highlightColor: Colors.white,
              child: Container(
                height: i == 0 ? 220.h : 60.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          ),
          childCount: 5,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 30.h, 32.w, 10.h),
      child: Column(
        children: [
          Icon(Icons.leaderboard_rounded,
              size: 56.sp, color: CrystalTheme.violetBright.withValues(alpha: 0.5)),
          SizedBox(height: 14.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: CrystalTheme.font,
              fontSize: 14.sp,
              height: 1.45,
              color: CrystalTheme.textSecondary,
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: CrystalTheme.lilacText),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}
