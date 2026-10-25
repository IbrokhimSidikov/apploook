/// The customer's level on the Crystal Shop board, from their crystals.
///
/// Category A is bronze, B gold, C diamond. The level follows the current
/// spendable balance, so spending crystals can drop it again.
///
/// This is display only: crystal prices still come from the tier the server
/// holds on the loyalty card (`LoyaltyCard.tier`), which staff set.
library;

import 'package:apploook/models/loyalty.dart';
import 'package:flutter/material.dart';

enum CrystalRank {
  bronze(
    category: 'A',
    minCrystals: 0,
    icon: Icons.workspace_premium_rounded,
    colors: [Color(0xFFF2C29B), Color(0xFFB8693A)],
    ink: Color(0xFF8A4A22),
  ),
  gold(
    category: 'B',
    minCrystals: 500,
    icon: Icons.emoji_events_rounded,
    colors: [Color(0xFFFFE58A), Color(0xFFE0A400)],
    ink: Color(0xFF9A6B00),
  ),
  diamond(
    category: 'C',
    minCrystals: 2000,
    icon: Icons.diamond_rounded,
    colors: [Color(0xFFC9F3FF), Color(0xFF6B4DE6)],
    ink: Color(0xFF4C2BB3),
  );

  const CrystalRank({
    required this.category,
    required this.minCrystals,
    required this.icon,
    required this.colors,
    required this.ink,
  });

  /// "A", "B" or "C". Internal only - customers see the rank name.
  final String category;

  /// Crystals needed to reach this level.
  final int minCrystals;
  final IconData icon;

  /// Light-to-dark gradient of the medal.
  final List<Color> colors;

  /// Text colour that reads on white next to the medal.
  final Color ink;

  static CrystalRank forCrystals(int crystals) {
    var rank = CrystalRank.bronze;
    for (final r in CrystalRank.values) {
      if (crystals >= r.minCrystals) rank = r;
    }
    return rank;
  }

  /// The rank name for the price tier on the loyalty card, so the tier is
  /// never shown to customers as a bare letter.
  static CrystalRank forTier(LoyaltyTier tier) => switch (tier) {
        LoyaltyTier.a => CrystalRank.bronze,
        LoyaltyTier.b => CrystalRank.gold,
        LoyaltyTier.c => CrystalRank.diamond,
      };

  /// The level above, or null at the top.
  CrystalRank? get next =>
      index + 1 < CrystalRank.values.length ? CrystalRank.values[index + 1] : null;
}
