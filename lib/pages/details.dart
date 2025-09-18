import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/models/cart_item.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/services/remote_config_service.dart';
import 'package:apploook/widget/widget_support.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';

class Details extends StatefulWidget {
  final dynamic product;

  const Details({Key? key, this.product}) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int a = 1;
  int quantity = 1;
  double unitPrice = 0;
  double totalPrice = 0;

  List<CategoryModel> categories = [];
  Map<String, List<SelectedModifier>> selectedModifiersByGroup = {};
  bool hasModifiers = false;

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (widget.product.description == null) {
      return null;
    }

    // If description is already a Map, use it directly
    if (widget.product.description is Map<String, dynamic>) {
      return widget.product.description[languageCode]?.toString();
    }

    // If description is a String, check if it looks like JSON
    if (widget.product.description is String) {
      String descStr = widget.product.description.toString().trim();
      if (descStr.isEmpty) {
        return null;
      }

      // Only try to parse as JSON if it starts with { or [
      if (descStr.startsWith('{') || descStr.startsWith('[')) {
        try {
          Map<String, dynamic> descriptionMap = json.decode(descStr);
          return descriptionMap[languageCode]?.toString();
        } catch (e) {
          // If JSON parsing fails, fall through to return raw string
        }
      }

      // Return the raw string for non-JSON descriptions
      return descStr;
    }

    // For any other type, convert to string
    return widget.product.description.toString();
  }

  @override
  void initState() {
    super.initState();
    _getCategories();
    unitPrice = widget.product.price;
    totalPrice = unitPrice * quantity;
    _initializeModifiers();
  }

  void _initializeModifiers() {
    if (widget.product.modifierGroups != null &&
        widget.product.modifierGroups.isNotEmpty) {
      hasModifiers = true;
      for (ModifierGroup group in widget.product.modifierGroups) {
        selectedModifiersByGroup[group.id] = [];

        // Always select the first modifier in each group by default
        if (group.modifiers.isNotEmpty) {
          selectedModifiersByGroup[group.id]!
              .add(SelectedModifier(modifier: group.modifiers[0], quantity: 1));
        }
      }
      _calculateTotalPrice();
    }
  }

  void _calculateTotalPrice() {
    double modifierPrice = 0.0;
    selectedModifiersByGroup.values.forEach((modifiers) {
      modifierPrice +=
          modifiers.fold(0.0, (sum, modifier) => sum + modifier.totalPrice);
    });
    setState(() {
      totalPrice = (unitPrice + modifierPrice) * quantity;
    });
  }

  void _toggleModifier(ModifierGroup group, Modifier modifier) {
    setState(() {
      List<SelectedModifier> currentSelection =
          selectedModifiersByGroup[group.id] ?? [];

      // Check if modifier is already selected
      int existingIndex = currentSelection
          .indexWhere((selected) => selected.modifier.id == modifier.id);

      if (existingIndex >= 0) {
        // If this is the only selected item, don't allow deselection
        // to ensure one option is always selected
        if (currentSelection.length > 1) {
          currentSelection.removeAt(existingIndex);
        }
      } else {
        // Always treat as radio button behavior - clear all and add new
        currentSelection.clear();
        currentSelection.add(SelectedModifier(modifier: modifier, quantity: 1));
      }

      selectedModifiersByGroup[group.id] = currentSelection;
      _calculateTotalPrice();
    });
  }

  bool _isModifierSelected(String groupId, String modifierId) {
    List<SelectedModifier> selection = selectedModifiersByGroup[groupId] ?? [];
    return selection.any((selected) => selected.modifier.id == modifierId);
  }

  // Check if current time is before the ordering cutoff time (configurable via Firebase Remote Config)
  bool _isOrderingTimeAllowed() {
    final now = DateTime.now();
    final remoteConfig = RemoteConfigService();
    final cutoffHour = remoteConfig.orderCutoffHour;
    final cutoffMinute = remoteConfig.orderCutoffMinute;

    // Log the values fetched from Firebase Remote Config
    // print('Firebase Remote Config - Order Cutoff Time: $cutoffHour:$cutoffMinute');
    // print('Current Time: ${now.hour}:${now.minute}');

    // Check if current time is before cutoff
    if (now.hour < cutoffHour) {
      return true;
    } else if (now.hour == cutoffHour && now.minute < cutoffMinute) {
      return true;
    }

    return false;
  }

  // Force refresh Remote Config values
  Future<void> _refreshRemoteConfig() async {
    final remoteConfig = RemoteConfigService();
    final updated = await remoteConfig.forceUpdate();

    // Show a snackbar with the result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remote Config ${updated ? 'updated' : 'not updated'}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Force UI update
      setState(() {});
    }
  }

  List<Widget> _buildModifierGroups() {
    if (widget.product.modifierGroups == null ||
        widget.product.modifierGroups.isEmpty) {
      return [];
    }

    return widget.product.modifierGroups.map<Widget>((group) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              group.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            'Choose ${group.minSelectedModifiers}-${group.maxSelectedModifiers}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...group.modifiers.map((modifier) {
            bool isSelected = _isModifierSelected(group.id, modifier.id);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFEC700)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  modifier.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: modifier.price > 0
                    ? Text(
                        '+${modifier.price.toStringAsFixed(0)} UZS',
                        style: const TextStyle(color: Colors.green),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFFFEC700))
                    : const Icon(Icons.radio_button_unchecked,
                        color: Colors.grey),
                onTap: () => _toggleModifier(group, modifier),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();

    var cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Image.network(
                        widget.product.imagePath,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 2.5,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: AppWidget.titleTextFieldStyle(),
                                ),
                                Text(
                                  widget.product.categoryTitle,
                                  style: AppWidget.HeadlineTextFieldStyle(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 48,
                          width: 140,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Color(0xFFD9D9D9)),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                        totalPrice = unitPrice * quantity;
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: const Icon(Icons.remove,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(width: 20.0),
                                Container(
                                  child: Text(
                                    quantity.toString(),
                                    style: AppWidget.semiboldTextFieldStyle(),
                                  ),
                                ),
                                SizedBox(width: 20.0),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      quantity++;
                                      totalPrice = unitPrice * quantity;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: const Icon(Icons.add,
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Consumer<LocaleProvider>(
                          builder: (context, localeProvider, _) {
                            return Text(
                              getDescriptionInLanguage(
                                      localeProvider.locale.languageCode) ??
                                  'No Description',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // Modifier Groups Section
                    if (hasModifiers) ..._buildModifierGroups(),
                    const SizedBox(height: 5.0),
                    // ChangeDrinks(categories: categories) // Uncomment if ChangeDrinks is needed
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                children: [
                  // Show warning message when ordering is not allowed
                  if (!_isOrderingTimeAllowed())
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            AppLocalizations.of(context).orderHoursValidation,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Debug button to refresh Remote Config (only in debug mode)
                        if (kDebugMode)
                          TextButton.icon(
                            onPressed: _refreshRemoteConfig,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Config'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).totalPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16.0,
                            ),
                          ),
                          Text(
                            "$totalPrice UZS",
                            style: AppWidget.boldTextFieldStyle(),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: ElevatedButton(
                          onPressed: _isOrderingTimeAllowed()
                              ? () {
                                  // Collect all selected modifiers
                                  List<SelectedModifier> allSelectedModifiers =
                                      [];
                                  selectedModifiersByGroup.values
                                      .forEach((modifiers) {
                                    allSelectedModifiers.addAll(modifiers);
                                  });

                                  // Create cart item with selected modifiers
                                  CartItem cartItem = CartItem(
                                    product: widget.product,
                                    quantity: quantity,
                                    selectedModifiers: allSelectedModifiers,
                                  );

                                  // Add to cart using the updated method
                                  cartProvider.addToCartWithModifiers(cartItem);
                                  cartProvider.logItems();
                                  Navigator.pushNamed(context, '/homeNew');
                                }
                              : null, // Button will be disabled after cutoff time
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                                const Color(0xFFFEC700)),
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            child: Text(
                              AppLocalizations.of(context).addToCart,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
