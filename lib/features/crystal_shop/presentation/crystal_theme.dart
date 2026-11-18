import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// The crystal artwork. Draw it with [CrystalIcon], never SvgPicture:
  /// Kristal.svg is a 1.2 MB auto-traced vector with ~3,200 paths, and
  /// drawing it live redrew all of them every frame wherever a crystal was
  /// visible (nav bar under the glass blur, menu cards), making the whole
  /// app janky.
  static const String asset = 'images/Kristal.svg';
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

/// The crystal icon. Renders [CrystalTheme.asset] (the SVG) to a bitmap once
/// per app run and shares that bitmap with every icon, so the SVG stays the
/// single source of the artwork without its per-frame drawing cost.
class CrystalIcon extends StatelessWidget {
  const CrystalIcon({super.key, this.width, this.height});

  final double? width;
  final double? height;

  /// Longest side of the shared bitmap. Covers the largest use (~80 logical
  /// px) at 3x density with headroom.
  static const double _rasterPx = 384;

  static ui.Image? _image;
  static Future<ui.Image>? _loading;
  static final ValueNotifier<ui.Image?> _ready = ValueNotifier(null);

  /// Starts the one-time render early (e.g. at app start) so the first
  /// crystal on screen does not appear a moment late. Safe to call often.
  static Future<void> precache() async {
    try {
      await _load();
    } catch (_) {
      // Logged in _load; icons stay empty rather than crashing.
    }
  }

  static Future<ui.Image> _load() {
    final cached = _image;
    if (cached != null) return Future.value(cached);
    return _loading ??= _rasterize().then((image) {
      _image = image;
      _ready.value = image;
      return image;
    }).catchError((Object e) {
      _loading = null; // allow a retry on the next build
      debugPrint('CrystalIcon: failed to render ${CrystalTheme.asset}: $e');
      throw e;
    });
  }

  static Future<ui.Image> _rasterize() async {
    final info = await vg.loadPicture(
        const SvgAssetLoader(CrystalTheme.asset), null);
    try {
      final scale =
          _rasterPx / math.max(info.size.width, info.size.height);
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..scale(scale)
        ..drawPicture(info.picture);
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(
          (info.size.width * scale).ceil(),
          (info.size.height * scale).ceil(),
        );
      } finally {
        picture.dispose();
      }
    } finally {
      info.picture.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) precache();
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: _ready,
      builder: (context, image, _) => image == null
          ? SizedBox(width: width, height: height ?? width)
          : RawImage(
              image: image,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}
