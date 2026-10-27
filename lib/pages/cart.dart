import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/crystal_shop/presentation/crystal_theme.dart';
import '../models/cart_item.dart';
import '../models/crystal_pricing.dart';
import '../pages/app_shell.dart';
import '../providers/loyalty_provider.dart';
import '../widgets/crystal_pay_toggle.dart';
import '../widgets/crystal_reward_card.dart';
import '../widgets/recommended_items_section.dart';

class Cart extends StatefulWidget {
  /// [embedded] is true when the cart lives inside the bottom tab bar, where
  /// there is nothing to go back to, so the back arrow is hidden.
  const Cart({Key? key, this.embedded = false}) : super(key: key);

  final bool embedded;

  /// Adds the mandatory package item when the cart has products. Exposed so
  /// the tab shell can re-run it each time the cart tab is opened, matching
  /// the old behaviour where the cart page was rebuilt on every visit.
  static Future<void> ensureMandatoryPackage(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    try {
      final menuService = MenuService();
      await menuService.initialize();
      cartProvider.ensureMandatoryPackage(menuService.allProducts);
    } catch (e) {
      print('Error ensuring mandatory package: $e');
    }
  }

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<CategoryModel> categories = [];

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  @override
  void initState() {
    super.initState();
    _getCategories();
    // Add mandatory package after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMandatoryPackage();
    });
  }

  void _ensureMandatoryPackage() => Cart.ensureMandatoryPackage(context);

  /// Back to the menu: the home tab when the cart is a tab, otherwise the
  /// screen underneath (or a fresh home when there is none).
  void _goToMenu() {
    if (AppShell.select(context, AppShell.homeTab)) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/homeNew', (route) => false);
    }
  }

  /// Whether [line] can take [extraUnits] more units within the crystal
  /// balance, given the basket already spends [cartCrystals]. Always true
  /// for money lines and while the balance is unknown.
  bool _fitsCrystalBudget(
    CartItem line,
    LoyaltyProvider loyalty,
    int cartCrystals, {
    required int extraUnits,
  }) {
    final budget = loyalty.crystalBudget;
    if (budget == null || !line.payWithCrystals) return true;
    final linePrice = CrystalPricing.linePrice(line, loyalty.tier);
    if (linePrice == null || line.quantity == 0) return true;
    final unit = linePrice ~/ line.quantity;
    return cartCrystals + unit * extraUnits <= budget;
  }

  Future<bool> _isUserSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    final firstName = prefs.getString('firstName');
    return phoneNumber != null &&
        phoneNumber.isNotEmpty &&
        firstName != null &&
        firstName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();

    var cartProvider = Provider.of<CartProvider>(context);
    final loyalty = context.watch<LoyaltyProvider>();
    final l10n = AppLocalizations.of(context);

    int getTotalQuantity(CartProvider cartProvider) {
      int totalQuantity = 0;
      for (var cartItem in cartProvider.cartItems) {
        totalQuantity += cartItem.quantity;
      }
      return totalQuantity;
    }

    // Lines paid with crystals contribute nothing to the money total; they
    // are summed separately so the customer sees both sides of the bill.
    double getTotalPrice(CartProvider cartProvider) {
      double totalPrice = 0;
      for (var cartItem in cartProvider.cartItems) {
        totalPrice += cartItem.moneyTotal;
      }
      return totalPrice;
    }

    int getTotalCrystals(CartProvider cartProvider) {
      int total = 0;
      for (var cartItem in cartProvider.cartItems) {
        if (!cartItem.payWithCrystals) continue;
        total += CrystalPricing.linePrice(cartItem, loyalty.tier) ?? 0;
      }
      return total;
    }

    int price = getTotalPrice(cartProvider).toInt();
    int crystals = getTotalCrystals(cartProvider);
    // Crystals the basket asks for beyond what the customer can spend.
    // Zero while the balance is unknown; checkout's quote still guards.
    final int? crystalBudget = loyalty.crystalBudget;
    final int crystalShortfall = crystalBudget == null
        ? 0
        : (crystals - crystalBudget).clamp(0, 1 << 30);
    int item = getTotalQuantity(cartProvider).toInt();

    // The quote is only live at checkout; outside it this is a no-op, so it
    // is safe to call after every cart change.
    void requote() => context.read<LoyaltyProvider>().requote();

    final checkoutLabel = [
      if (price > 0 || crystals == 0)
        '${NumberFormat('#,##0').format(price)} UZS',
      if (crystals > 0) l10n.crystalsAmount(crystals),
    ].join(' + ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).cart,
          style: TextStyle(color: Colors.black, fontSize: 18.sp),
        ),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/homeNew', (route) => false);
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(left: 10.w),
                  child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
                ),
              ),
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 10.w),
              child: IconButton(
                onPressed: () {
                  cartProvider.clearCart();
                  requote();
                },
                icon: const Icon(Icons.delete),
                tooltip: 'Clear Cart',
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      // ── Sticky checkout bar ────────────────────────────────────────────────
      // A basket paid entirely with crystals has a zero money total but
      // still has to reach checkout, so the bar keys off the item count.
      bottomNavigationBar: item > 0
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (crystalShortfall > 0)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16.sp, color: CrystalTheme.lilacText),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                l10n.checkoutNotEnoughCrystals(
                                    crystalShortfall),
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: CrystalTheme.lilacText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: crystalShortfall > 0
                            ? null
                            : () async {
                                final cartProvider = Provider.of<CartProvider>(
                                    context,
                                    listen: false);
                                print(
                                    '\n======== CART → CHECKOUT: Cart Items ========');
                                print(
                                    'Total Items: ${cartProvider.cartItems.length}');
                                print(
                                    'Total Price: ${cartProvider.getTotalPrice()} UZS');
                                for (int i = 0;
                                    i < cartProvider.cartItems.length;
                                    i++) {
                                  final item = cartProvider.cartItems[i];
                                  print('\n--- Item ${i + 1} ---');
                                  print('Product ID: ${item.product.id}');
                                  print('Product UUID: ${item.product.uuid}');
                                  print('Product Name: ${item.product.name}');
                                  print('Display Name: ${item.displayName}');
                                  print('Quantity: ${item.quantity}');
                                  print(
                                      'Base Price: ${item.product.price} UZS');
                                  print(
                                      'Total Price (with modifiers): ${item.totalPrice} UZS');
                                  if (item.selectedModifiers.isNotEmpty) {
                                    print(
                                        'Selected Modifiers (${item.selectedModifiers.length}):');
                                    double modifiersTotal = 0.0;
                                    for (var modifier
                                        in item.selectedModifiers) {
                                      final modPrice = modifier.modifier.price *
                                          modifier.quantity;
                                      modifiersTotal += modPrice;
                                      print('  - ${modifier.modifier.name}');
                                      print('    ID: ${modifier.modifier.id}');
                                      print(
                                          '    Price: ${modifier.modifier.price} UZS');
                                      print(
                                          '    Quantity: ${modifier.quantity}');
                                      print('    Subtotal: $modPrice UZS');
                                    }
                                    print(
                                        'Total Modifiers Cost: $modifiersTotal UZS');
                                    print(
                                        'Item Total (Base + Modifiers) × Quantity: ${(item.product.price + modifiersTotal) * item.quantity} UZS');
                                  } else {
                                    print('No modifiers selected');
                                  }
                                }
                                print(
                                    '============================================\n');
                                bool isSignedIn = await _isUserSignedIn();
                                Navigator.pushNamed(
                                  context,
                                  isSignedIn ? '/checkout' : '/signin',
                                );
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEC700),
                          disabledBackgroundColor: const Color(0xFFEDEBF4),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                        child: Text(
                          '${l10n.proceedToCheckout} — $checkoutLabel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: cartProvider.cartItems.isEmpty
            ? _EmptyCart(onBrowseMenu: _goToMenu)
            : ColoredBox(
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    // ── Summary header ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$item ${item == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${NumberFormat('#,##0').format(price)} UZS',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (crystals > 0) ...[
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(CrystalTheme.asset,
                                          width: 19.w, height: 19.w),
                                      SizedBox(width: 4.w),
                                      Text(
                                        l10n.spendCrystals(crystals),
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: CrystalTheme.lilacText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: Divider(height: 1, thickness: 1),
                    ),

                    // ── Cart items ─────────────────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final cartItem = cartProvider.cartItems[index];
                          final isMandatoryPackage =
                              cartItem.product.name == 'Пакет';

                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: cartItem.product.imagePath != null
                                          ? Image.network(
                                              cartItem.product.imagePath,
                                              width: 90.w,
                                              height: 64.w,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 64.w,
                                                height: 64.w,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              width: 64.w,
                                              height: 64.w,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  color: Colors.grey),
                                            ),
                                    ),
                                    SizedBox(width: 12.w),

                                    // Name + price
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  cartItem.displayName,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (isMandatoryPackage)
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      left: 4.w),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFEC700),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.r),
                                                  ),
                                                  child: Text(
                                                    'Required',
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          _LinePricing(
                                            line: cartItem,
                                            loyalty: loyalty,
                                            isMandatoryPackage:
                                                isMandatoryPackage,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),

                                    // Quantity control
                                    if (!isMandatoryPackage)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(50.r),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _QtyButton(
                                              icon: cartItem.quantity > 1
                                                  ? Icons.remove
                                                  : Icons.delete_outline,
                                              iconColor: cartItem.quantity > 1
                                                  ? Colors.black
                                                  : Colors.red,
                                              onTap: () {
                                                if (cartItem.quantity > 1) {
                                                  cartProvider.updateQuantity(
                                                      cartItem,
                                                      cartItem.quantity - 1);
                                                } else {
                                                  cartProvider
                                                      .removeFromCart(cartItem);
                                                }
                                                requote();
                                              },
                                            ),
                                            SizedBox(
                                              width: 28.w,
                                              child: Center(
                                                child: Text(
                                                  '${cartItem.quantity}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            _QtyButton(
                                              icon: Icons.add,
                                              // A crystal line stops growing once
                                              // one more unit would overdraw.
                                              onTap: _fitsCrystalBudget(
                                                      cartItem,
                                                      loyalty,
                                                      crystals,
                                                      extraUnits: 1)
                                                  ? () {
                                                      cartProvider
                                                          .updateQuantity(
                                                              cartItem,
                                                              cartItem.quantity +
                                                                  1);
                                                      requote();
                                                    }
                                                  : null,
                                              iconColor: _fitsCrystalBudget(
                                                      cartItem,
                                                      loyalty,
                                                      crystals,
                                                      extraUnits: 1)
                                                  ? Colors.black
                                                  : Colors.black26,
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(50.r),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 14.w, vertical: 8.h),
                                        child: Text(
                                          '${cartItem.quantity}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(
                                  height: 1, thickness: 1, indent: 88),
                            ],
                          );
                        },
                        childCount: cartProvider.cartItems.length,
                      ),
                    ),

                    // ── Recommended items ──────────────────────────────────────
                    const SliverToBoxAdapter(child: RecommendedItemsSection()),

                    // Bottom padding so content clears the sticky button
                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
/// Shown instead of the cart list when nothing is in the basket. No
/// suggestions here: the page should read as empty, with one clear way back
/// to the menu.
class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowseMenu});

  final VoidCallback onBrowseMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(32.w, 24.h, 32.w, 48.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 56.sp,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.cartEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.cartEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.45,
                color: const Color(0xFF8E8E93),
              ),
            ),
            SizedBox(height: 28.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: TextButton(
                onPressed: onBrowseMenu,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFEC700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                ),
                child: Text(
                  l10n.cartEmptyAction,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price, earn chip and crystal toggle of one cart line ─────────────────────
class _LinePricing extends StatelessWidget {
  const _LinePricing({
    required this.line,
    required this.loyalty,
    required this.isMandatoryPackage,
  });

  final CartItem line;
  final LoyaltyProvider loyalty;
  final bool isMandatoryPackage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money =
        '${NumberFormat('#,##0').format(line.totalPrice.toInt())} UZS';

    // The bag is never offered for crystals and earns nothing.
    if (isMandatoryPackage) return _moneyText(money);

    final crystalOnly = CrystalPricing.lineIsCrystalOnly(line);
    final crystalPrice = CrystalPricing.linePrice(line, loyalty.tier);
    // A crystal-only line stays marked as paying with crystals even when it
    // cannot be bought right now (signed out, no tier price): showing a soum
    // price for it would promise something the server will refuse.
    final payingWithCrystals = line.payWithCrystals || crystalOnly;
    final points = CrystalPricing.linePoints(line);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payingWithCrystals && crystalPrice != null)
          Row(
            children: [
              CrystalPriceText(crystals: crystalPrice),
              SizedBox(width: 8.w),
              Text(
                money,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          )
        else
          _moneyText(money),
        if (!payingWithCrystals && points > 0) ...[
          SizedBox(height: 6.h),
          CrystalRewardChip(crystals: points),
        ],
        // The toggle needs a session and a tier price; otherwise a
        // crystal-only line still explains why it cannot be bought.
        if (crystalPrice != null && loyalty.hasSession) ...[
          SizedBox(height: 6.h),
          CrystalPayToggle(
            crystalPrice: crystalPrice,
            value: line.payWithCrystals,
            crystalOnly: crystalOnly,
            onChanged: crystalOnly
                ? null
                : (value) {
                    // Switching a line to crystals must fit what is left
                    // of the balance after the other crystal lines.
                    final budget = loyalty.crystalBudget;
                    if (value && budget != null) {
                      final inCart = CrystalPricing.cartCrystals(
                        context.read<CartProvider>().cartItems,
                        loyalty.tier,
                      );
                      final missing = inCart + crystalPrice - budget;
                      if (missing > 0) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: CrystalTheme.violetDeep,
                            content: Text(
                                l10n.notEnoughCrystalsForQuantity(missing)),
                          ));
                        return;
                      }
                    }
                    context
                        .read<LoyaltyProvider>()
                        .setLinePayWithCrystals(line, value);
                  },
          ),
        ] else if (crystalOnly) ...[
          SizedBox(height: 6.h),
          if (!loyalty.hasSession)
            const CrystalOnlySignInHint()
          else
            // Signed in but the tier has no crystal price for it.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CrystalOnlyBadge(),
                SizedBox(height: 4.h),
                Text(
                  l10n.crystalNotSoldAtTier,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: CrystalTheme.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _moneyText(String money) => Text(
        money,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      );
}

// ── Small helper widget for quantity +/- buttons ──────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;

  const _QtyButton({
    required this.icon,
    this.onTap,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.r),
        child: Icon(icon, size: 18.w, color: iconColor),
      ),
    );
  }
}
