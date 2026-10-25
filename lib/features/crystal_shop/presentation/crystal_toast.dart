import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'crystal_theme.dart';

/// A compact pill notice that floats just above the glass bottom bar.
///
/// The stock SnackBar is anchored to the nearest Scaffold, and the shop's
/// Scaffold knows nothing about the shell's floating bar, so a snackbar sat
/// on top of it. This draws into the root overlay instead and uses the
/// bottom padding the shell reserves for its bar, so it always lands in the
/// gap above it. One toast at a time: a new one replaces the previous.
class CrystalToast {
  CrystalToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    // The shell reports the space its bar occupies as bottom padding, so
    // this is already "above the bar" on a shell tab and the plain safe
    // area anywhere else.
    final double bottom = MediaQuery.of(context).padding.bottom + 12.h;

    dismiss();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        bottom: bottom,
        message: message,
        actionLabel: actionLabel,
        duration: duration,
        onAction: onAction,
        onClosed: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.bottom,
    required this.message,
    required this.duration,
    required this.onClosed,
    this.actionLabel,
    this.onAction,
  });

  final double bottom;
  final String message;
  final String? actionLabel;
  final Duration duration;
  final VoidCallback onClosed;
  final VoidCallback? onAction;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.6),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onClosed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.bottom,
      child: IgnorePointer(
        ignoring: _closing,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: Dismissible(
                key: const ValueKey('crystal-toast'),
                direction: DismissDirection.down,
                onDismissed: (_) => widget.onClosed(),
                child: Material(
                  color: CrystalTheme.violetDeep,
                  elevation: 10,
                  shadowColor: CrystalTheme.violet.withValues(alpha: 0.45),
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 340.w),
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(14.w, 9.h, 6.w, 9.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(CrystalTheme.asset,
                              width: 16.w, height: 16.w),
                          SizedBox(width: 9.w),
                          Flexible(
                            child: Text(
                              widget.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: CrystalTheme.font,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null) ...[
                            SizedBox(width: 6.w),
                            TextButton(
                              onPressed: () {
                                widget.onAction?.call();
                                _close();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: CrystalTheme.yellow,
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                shape: const StadiumBorder(),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: TextStyle(
                                  fontFamily: CrystalTheme.font,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else
                            SizedBox(width: 8.w),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
