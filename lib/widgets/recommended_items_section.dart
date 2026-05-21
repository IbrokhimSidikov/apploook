import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/widget/cached_product_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Displays a "You might also like" section in the Cart page.
///
/// Data source priority:
///  1. Explicit recommendations from [MenuService.recommendedProductsByCategory]
///     (populated when the backend sends `recommendedProductsByCategory`).
///  2. Auto-recommendations via [MenuService.getAutoRecommendedProducts]
///     (smart fallback: pinned / first products per category, excluding cart items).
///
/// `MenuService` is a singleton already initialized before the cart opens,
/// so no async initialization is needed here.
class RecommendedItemsSection extends StatelessWidget {
  const RecommendedItemsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Read cart items so we can exclude them from recommendations
    final cartProvider = context.watch<CartProvider>();
    final cartUuids =
        cartProvider.cartItems.map((ci) => ci.product.uuid as String).toSet();

    final menuService = MenuService();

    if (!menuService.isInitialized) {
      // Service not ready yet – show nothing silently
      return const SizedBox.shrink();
    }

    // 1. Try explicit backend recommendations
    Map<String, List<Product>> recommended =
        menuService.getRecommendedProductsByCategory();

    // 2. Fallback to automatic smart recommendations
    if (recommended.isEmpty) {
      recommended = menuService.getAutoRecommendedProducts(
        cartProductUuids: cartUuids,
      );
    } else {
      // Filter out cart items from explicit recommendations too
      recommended = {
        for (final entry in recommended.entries)
          if (entry.value.where((p) => !cartUuids.contains(p.uuid)).isNotEmpty)
            entry.key:
                entry.value.where((p) => !cartUuids.contains(p.uuid)).toList(),
      };
    }

    if (recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            AppLocalizations.of(context).recommendedTitle,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...recommended.entries.map((entry) => _CategoryRow(
              categoryLabel: entry.key,
              products: entry.value,
            )),
        SizedBox(height: 8.h),
      ],
    );
  }
}

// ─── Per-category horizontal row ─────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String categoryLabel;
  final List<Product> products;

  const _CategoryRow({
    required this.categoryLabel,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 4.h, bottom: 6.h),
          child: Text(
            categoryLabel,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(
          height: 185.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) =>
                _ProductCard(product: products[index]),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

// ─── Single product card ──────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  void _handleAdd(BuildContext context) {
    if (product.modifierGroups.isNotEmpty) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => Details(product: product)),
      );
    } else {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.addToCart(product, 1);
      _showAddedSnackBar(context);
    }
  }

  void _showAddedSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(50.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Yellow check badge
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEC700),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 18.w,
                  ),
                ),
                SizedBox(width: 12.w),
                // Product name + label
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.addedToCart,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Price pill
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEC700),
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Text(
                    '${NumberFormat('#,##0').format(product.price.toInt())} UZS',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat('#,##0').format(product.price.toInt());

    return GestureDetector(
      onTap: () => _handleAdd(context),
      child: Container(
        width: 130.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              child: SizedBox(
                height: 90.h,
                width: double.infinity,
                child: product.imagePath != null
                    ? CachedProductImage(
                        imageUrl: product.imagePath!,
                        width: 130.w,
                        height: 90.h,
                        boxFit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: 28.w,
                          ),
                        ),
                      ),
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$formattedPrice UZS',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleAdd(context),
                          child: Container(
                            width: 26.w,
                            height: 26.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEC700),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              product.modifierGroups.isNotEmpty
                                  ? Icons.open_in_new
                                  : Icons.add,
                              size: 16.w,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
