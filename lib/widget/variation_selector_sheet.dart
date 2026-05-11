import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/product_group.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/widget/cached_product_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom sheet widget for selecting product variations
class VariationSelectorSheet extends StatelessWidget {
  final ProductGroup productGroup;

  const VariationSelectorSheet({
    super.key,
    required this.productGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    productGroup.groupName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Variations list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: productGroup.variations.length,
              itemBuilder: (context, index) {
                final variation = productGroup.variations[index];
                return _buildVariationItem(context, variation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationItem(BuildContext context, Product variation) {
    return InkWell(
      onTap: () {
        // Close the bottom sheet
        Navigator.pop(context);
        
        // Navigate to details page with the selected variation
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => Details(product: variation),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image
            if (variation.imagePath != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedProductImage(
                    imageUrl: variation.imagePath!,
                    width: 100,
                    height: 80,
                  ),
                ),
              ),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variation.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      final description = variation.getDescriptionInLanguage(
                        localeProvider.locale.languageCode,
                      );

                      if (description != null && description.isNotEmpty) {
                        return Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEC700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${variation.price.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]} ',
                )} UZS',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the variation selector bottom sheet
  static Future<void> show(BuildContext context, ProductGroup productGroup) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VariationSelectorSheet(productGroup: productGroup),
    );
  }
}
