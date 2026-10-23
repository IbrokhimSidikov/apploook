import 'package:flutter/material.dart';

/// Palette for the Crystal Shop. Deep violet header with the brand yellow
/// as the action colour, so the tab feels premium but still part of LOOOK.
abstract class CrystalTheme {
  static const Color ink = Color(0xFF14102A);
  static const Color violetDeep = Color(0xFF1B1140);
  static const Color violet = Color(0xFF3B2185);
  static const Color violetBright = Color(0xFF6B4DE6);
  static const Color lilac = Color(0xFFEFE9FF);
  static const Color lilacText = Color(0xFF4C2BB3);
  static const Color yellow = Color(0xFFFEC700);
  static const Color amber = Color(0xFFE8590C);
  static const Color page = Color(0xFFF8F7FC);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFECE9F5);
  static const Color textSecondary = Color(0xFF7B7791);

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1140), Color(0xFF3B2185), Color(0xFF5A3BC9)],
    stops: [0.0, 0.6, 1.0],
  );

  static const String asset = 'images/crystal.svg';
  static const String font = 'Poppins';
}

/// Soft radial light used behind the violet [CrystalTheme.header] surfaces
/// (the shop header, the profile crystal card) for depth.
class CrystalBloom extends StatelessWidget {
  const CrystalBloom({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
