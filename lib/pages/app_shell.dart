import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cart_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_bottom_nav_bar.dart';
import 'cart.dart';
import '../features/crystal_shop/presentation/crystal_shop_page.dart';
import 'homenew.dart';
import 'profile.dart';

/// Root screen after sign-in: the four main tabs behind a floating glass
/// tab bar. The `/homeNew` route resolves here, so every existing
/// "go home" navigation lands on the Home tab unchanged.
///
/// Tabs are built lazily on first visit and then kept alive in an
/// [IndexedStack], so Home keeps its scroll position and loaded menu while
/// the user browses the other tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  static const int homeTab = 0;
  static const int shopTab = 1;
  static const int cartTab = 2;
  static const int profileTab = 3;

  /// Switches the shell to [tab] from anywhere inside it, so a screen that
  /// lives in a tab is shown in place rather than pushed as a second copy
  /// with its own back button. Returns false when [context] is not under a
  /// shell (a pushed route), in which case the caller navigates instead.
  static bool select(BuildContext context, int tab) {
    final shell = context.findAncestorStateOfType<_AppShellState>();
    if (shell == null) return false;
    shell._select(tab);
    return true;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _tabCount = 4;

  late int _index = widget.initialIndex.clamp(0, _tabCount - 1);
  final List<Widget?> _pages = List<Widget?>.filled(_tabCount, null);

  Widget _buildPage(int index) {
    switch (index) {
      case AppShell.shopTab:
        return const CrystalShop();
      case AppShell.cartTab:
        return const Cart(embedded: true);
      case AppShell.profileTab:
        return const Profile();
      case AppShell.homeTab:
      default:
        return const HomeNew();
    }
  }

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    if (index == AppShell.cartTab) {
      // The old cart page re-ran this on every push; keep that behaviour.
      Cart.ensureMandatoryPackage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final int cartCount = context.watch<CartProvider>().showQuantity();

    // Float the pill just above the home indicator; on devices without one
    // give it a fixed gutter instead.
    final double safeBottom = mq.padding.bottom;
    final double barBottom = safeBottom > 0 ? safeBottom + 6 : 16;
    // Pages see this as their bottom safe-area so SafeArea / sticky buttons
    // automatically sit above the bar instead of underneath it.
    final double reservedBottom = barBottom + GlassBottomNavBar.height + 10;

    // Build only the current tab plus the ones already visited.
    _pages[_index] ??= _buildPage(_index);
    final children = <Widget>[
      for (var i = 0; i < _tabCount; i++) _pages[i] ?? const SizedBox.shrink(),
    ];

    return PopScope(
      // Android back on a secondary tab returns to Home before leaving.
      canPop: _index == AppShell.homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = AppShell.homeTab);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: reservedBottom),
                viewPadding: mq.viewPadding.copyWith(bottom: reservedBottom),
              ),
              child: IndexedStack(index: _index, children: children),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: barBottom,
              child: GlassBottomNavBar(
                currentIndex: _index,
                onTap: _select,
                items: [
                  GlassNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l.home,
                  ),
                  GlassNavItem(
                    icon: Icons.diamond_outlined,
                    activeIcon: Icons.diamond_rounded,
                    label: l.shop,
                  ),
                  GlassNavItem(
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                    label: l.cart,
                    badgeCount: cartCount,
                  ),
                  GlassNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: l.profile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
