import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_config_service.dart';

/// Full-screen, Instagram-story-style announcement overlay.
///
/// Driven by Remote Config: see [RemoteConfigService.announcementEnabled]
/// and friends. Call [AnnouncementStory.maybeShow] once after the home
/// screen is ready — it no-ops if there's nothing to show or the user
/// has already reached the per-id view cap.
class AnnouncementStory extends StatefulWidget {
  final String imageUrl;
  final Duration duration;
  final String? linkUrl;

  /// The image's natural width / height. When provided, the card is sized
  /// to this ratio so the whole poster is visible without cropping or
  /// letterbox. When null, the card falls back to a full-bleed layout
  /// with [BoxFit.contain] (so nothing is cropped, but letterbox bars
  /// may appear above/below).
  final double? imageAspectRatio;

  const AnnouncementStory({
    super.key,
    required this.imageUrl,
    required this.duration,
    this.linkUrl,
    this.imageAspectRatio,
  });

  /// Resolves the image to its natural pixel dimensions and returns
  /// width/height. Returns null if the image can't be decoded — callers
  /// should treat null as "use the full-bleed fallback layout".
  static Future<double?> _resolveAspectRatio(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    try {
      final img = await completer.future;
      if (img.height == 0) return null;
      return img.width / img.height;
    } catch (_) {
      return null;
    }
  }

  // SharedPreferences keys storing the last announcement id the user saw
  // and how many times they've seen it. Pairing them lets us reset the
  // count automatically when a new announcement id is published.
  static const _seenIdKey = 'announcement_seen_id';
  static const _seenCountKey = 'announcement_seen_count';

  /// Debug-only: forces the announcement to render using whatever Remote
  /// Config currently has, ignoring the enabled flag and the "seen" record,
  /// and without marking the id as seen afterwards. Refreshes Remote Config
  /// first so previewing right after publishing reflects the latest values.
  static Future<void> preview(BuildContext context) async {
    final config = RemoteConfigService();
    await config.forceUpdate();

    final imageUrl = config.announcementImageUrl;
    if (imageUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No 'announcement_image_url' in Remote Config — nothing to preview.",
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final imageProvider = CachedNetworkImageProvider(imageUrl);
    try {
      await precacheImage(imageProvider, context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch announcement image.'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final aspect = await _resolveAspectRatio(imageProvider);
    if (!context.mounted) return;

    final link = config.announcementLinkUrl;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => AnnouncementStory(
          imageUrl: imageUrl,
          duration: Duration(seconds: config.announcementDurationSeconds),
          linkUrl: link.isEmpty ? null : link,
          imageAspectRatio: aspect,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Debug-only: clears the seen id and view count so the next cold launch
  /// will trigger [maybeShow] for the currently published announcement id
  /// from a fresh count of 0.
  static Future<void> resetSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenIdKey);
    await prefs.remove(_seenCountKey);
  }

  /// Reads the current per-id view count. If the stored id no longer
  /// matches the published [RemoteConfigService.announcementId], the
  /// stored count is treated as 0 (a new announcement starts fresh).
  static Future<({String? storedId, int count, int max})> debugStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final config = RemoteConfigService();
    final storedId = prefs.getString(_seenIdKey);
    final currentId = config.announcementId;
    final rawCount = prefs.getInt(_seenCountKey) ?? 0;
    final count =
        (storedId != null && storedId == currentId) ? rawCount : 0;
    return (storedId: storedId, count: count, max: config.announcementMaxShows);
  }

  /// Resolves quietly if there is no active announcement, the user has
  /// already hit the per-id view cap, an app update is required (so the
  /// update dialog should dominate), or the image fails to precache.
  static Future<void> maybeShow(BuildContext context) async {
    final config = RemoteConfigService();

    // Don't pile on top of the mandatory-update dialog.
    if (await config.isUpdateRequired()) return;

    if (!config.announcementEnabled) return;
    final id = config.announcementId;
    final imageUrl = config.announcementImageUrl;
    if (id.isEmpty || imageUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_seenIdKey);
    final maxShows = config.announcementMaxShows;
    // If the stored id doesn't match the currently published id, the
    // count resets to 0 — a new announcement starts its own cap fresh.
    final priorCount = (storedId == id) ? (prefs.getInt(_seenCountKey) ?? 0) : 0;
    if (priorCount >= maxShows) return;

    if (!context.mounted) return;

    // Precache so the story never opens onto a blank frame. If the image
    // can't be fetched, skip entirely — better than showing an empty box,
    // and we'll retry next launch since we haven't incremented the count.
    final imageProvider = CachedNetworkImageProvider(imageUrl);
    try {
      await precacheImage(imageProvider, context);
    } catch (_) {
      return;
    }

    if (!context.mounted) return;

    final aspect = await _resolveAspectRatio(imageProvider);
    if (!context.mounted) return;

    // Increment now: tapping through, swiping away, or even a crash mid-view
    // all count as a "show". Prevents respawning unboundedly if something
    // goes sideways. We always write the id alongside the count so a stale
    // id from a previous announcement can't accidentally inflate the new one.
    await prefs.setString(_seenIdKey, id);
    await prefs.setInt(_seenCountKey, priorCount + 1);

    if (!context.mounted) return;

    final link = config.announcementLinkUrl;

    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => AnnouncementStory(
          imageUrl: imageUrl,
          duration: Duration(seconds: config.announcementDurationSeconds),
          linkUrl: link.isEmpty ? null : link,
          imageAspectRatio: aspect,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<AnnouncementStory> createState() => _AnnouncementStoryState();
}

class _AnnouncementStoryState extends State<AnnouncementStory>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  bool _dismissing = false;
  bool _paused = false;
  double _dragOffset = 0;

  static const double _dismissDragThreshold = 120;
  static const double _dismissVelocityThreshold = 700;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      });
    // Start after first frame so the entry transition isn't stolen by the timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _progress.forward();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _pause() {
    if (_paused || _dismissing) return;
    _paused = true;
    _progress.stop(canceled: false);
  }

  void _resume() {
    if (!_paused || _dismissing) return;
    _paused = false;
    _progress.forward();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    Navigator.of(context).pop();
  }

  Future<void> _handleTap() async {
    final link = widget.linkUrl;
    if (link == null || link.isEmpty) {
      _dismiss();
      return;
    }
    // Close first so the story doesn't linger over the destination.
    final navigator = Navigator.of(context);
    if (!_dismissing) {
      _dismissing = true;
      navigator.pop();
    }
    try {
      final uri = Uri.parse(link);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort: the popup is already closed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dragProgress = (_dragOffset / 400).clamp(0.0, 1.0);
    final backdropOpacity = (1 - dragProgress) * 0.88;
    final cardOpacity = (1 - dragProgress * 0.6).clamp(0.0, 1.0);
    final cardScale = 1 - dragProgress * 0.06;

    final aspect = widget.imageAspectRatio;
    // Card content — the image plus the story-style top overlay (progress
    // bar + close button). When we know the natural aspect ratio the card
    // adopts it (no crop, no letterbox); otherwise we fill the safe area
    // and fit the image with [BoxFit.contain] (no crop, but possible
    // letterbox above/below).
    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: aspect != null ? BoxFit.cover : BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => Container(color: Colors.black),
            errorWidget: (_, __, ___) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
          // Top gradient + progress + close, anchored to the card top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: 14,
                left: 14,
                right: 14,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) =>
                        _StoryProgressBar(value: _progress.value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StoryCloseButton(onTap: _dismiss),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // The gesture surface wraps the card so taps/long-press/drag are
    // bound to the card itself, not the surrounding backdrop.
    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPressStart: (_) => _pause(),
      onLongPressEnd: (_) => _resume(),
      onLongPressCancel: _resume,
      onVerticalDragUpdate: (d) {
        if (_dismissing) return;
        // Only allow downward drag.
        final next =
            (_dragOffset + d.delta.dy).clamp(0.0, double.infinity);
        if (next != _dragOffset) {
          setState(() => _dragOffset = next);
        }
      },
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (_dragOffset > _dismissDragThreshold ||
            v > _dismissVelocityThreshold) {
          _dismiss();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: aspect != null
          ? AspectRatio(aspectRatio: aspect, child: cardContent)
          : SizedBox.expand(child: cardContent),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop — tap-to-dismiss when the card is smaller than the
          // screen. Fades out as the user drags the card down.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child:
                  Container(color: Colors.black.withOpacity(backdropOpacity)),
            ),
          ),
          // Centered card. Padding keeps the card off the status bar /
          // home indicator on phones where the card matches screen size.
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: media.padding.top + 16,
                bottom: media.padding.bottom + 16,
                left: 12,
                right: 12,
              ),
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Transform.scale(
                  scale: cardScale,
                  child: Opacity(
                    opacity: cardOpacity,
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryProgressBar extends StatelessWidget {
  final double value;
  const _StoryProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(color: Colors.white.withOpacity(0.28)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StoryCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
