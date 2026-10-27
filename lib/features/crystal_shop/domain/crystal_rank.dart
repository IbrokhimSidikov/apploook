/// The customer's level as shown in the app: tier A is bronze, B gold,
/// C diamond. The letters never reach the screen.
///
/// The level comes from `/loyalty/tier` (earned from recent purchases);
/// crystal prices still come from the tier on the loyalty card.
library;

import 'package:apploook/models/loyalty.dart';
import 'package:flutter/material.dart';

enum CrystalRank {
  bronze(
    category: 'A',
    icon: Icons.workspace_premium_rounded,
    colors: [Color(0xFFF2C29B), Color(0xFFB8693A)],
    ink: Color(0xFF8A4A22),
  ),
  gold(
    category: 'B',
    icon: Icons.emoji_events_rounded,
    colors: [Color(0xFFFFE58A), Color(0xFFE0A400)],
    ink: Color(0xFF9A6B00),
  ),
  diamond(
    category: 'C',
    icon: Icons.diamond_rounded,
    colors: [Color(0xFFC9F3FF), Color(0xFF6B4DE6)],
    ink: Color(0xFF4C2BB3),
  );

  const CrystalRank({
    required this.category,
    required this.icon,
    required this.colors,
    required this.ink,
  });

  /// "A", "B" or "C". Internal only - customers see the rank name.
  final String category;

  final IconData icon;

  /// Light-to-dark gradient of the medal.
  final List<Color> colors;

  /// Text colour that reads on white next to the medal.
  final Color ink;

  /// The rank for a tier letter, so the tier is never shown to customers
  /// as a bare letter.
  static CrystalRank forTier(LoyaltyTier tier) => switch (tier) {
        LoyaltyTier.a => CrystalRank.bronze,
        LoyaltyTier.b => CrystalRank.gold,
        LoyaltyTier.c => CrystalRank.diamond,
      };

  /// The level above, or null at the top.
  CrystalRank? get next =>
      index + 1 < CrystalRank.values.length ? CrystalRank.values[index + 1] : null;
}
