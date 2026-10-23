import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

/// One entry in the floating tab bar.
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Small red counter drawn over the icon. Hidden when zero.
  final int badgeCount;
}

/// The round action in the middle of the bar, e.g. the payment QR.
class GlassNavAction {
  const GlassNavAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.cx0B0B0B,
    this.iconColor = AppColors.cxFEC700,
  });

  final IconData icon;

  /// Fill of the disc and colour of the icon on it.
  final Color color;
  final Color iconColor;

  /// Read out by screen readers; the button itself shows only the icon.
  final String label;
  final VoidCallback onTap;
}

/// iOS-style floating tab bar: a rounded pill with a frosted-glass surface
/// that lets the page content blur through underneath it.
///
/// The bar is purely presentational. Whoever places it is responsible for
/// keeping page content clear of it (see `AppShell`, which inflates the
/// bottom MediaQuery padding by [height] plus its margins).
class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAction,
  });

  /// Logical height of the pill. Kept a plain constant (not screen-scaled)
  /// so layout code can reserve space for it without a BuildContext.
  static const double height = 66;

  /// Side gutter between the pill and the screen edge.
  static const double horizontalMargin = 20;

  static const double _radius = 33;

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional round action button drawn in the middle of the bar, between
  /// the two halves of [items]. It is not a tab: it never takes the
  /// selection and does not shift the indices passed to [onTap].
  final GlassNavAction? centerAction;

  @override
  Widget build(BuildContext context) {
    final int split = (items.length / 2).ceil();
    Widget tab(int i) => Expanded(
          child: _GlassNavButton(
            item: items[i],
            selected: i == currentIndex,
            onTap: () => onTap(i),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: DecoratedBox(
        // Shadow lives outside the clip so it is not cut off.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                // Translucent white over the blurred page: the frosted look.
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.82),
                    Colors.white.withOpacity(0.66),
                  ],
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < split; i++) tab(i),
                  if (centerAction != null)
                    Expanded(child: _GlassCenterButton(action: centerAction!)),
                  for (var i = split; i < items.length; i++) tab(i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? AppColors.cx0B0B0B : const Color(0xFF7A7A7A);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The selected tab sits on a yellow pill; the pill fades and
            // scales in rather than popping, like the iOS tab highlight.
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: 54,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.cxFEC700 : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      key: ValueKey<bool>(selected),
                      size: 22,
                      color: foreground,
                    ),
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      top: -5,
                      right: 6,
                      child: _Badge(count: item.badgeCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _duration,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.sp,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid disc with an icon, so it reads as an action rather than one
/// more tab next to the yellow selected-tab pill.
class _GlassCenterButton extends StatelessWidget {
  const _GlassCenterButton({required this.action});

  final GlassNavAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onTap,
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: action.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(action.icon, size: 26, color: action.iconColor),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 9,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
