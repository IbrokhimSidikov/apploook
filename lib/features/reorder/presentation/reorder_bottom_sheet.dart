import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../cart_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/reorder_controller.dart';
import '../domain/last_order.dart';

class ReorderBottomSheet extends StatefulWidget {
  const ReorderBottomSheet({super.key, required this.order});

  final LastOrder order;

  @override
  State<ReorderBottomSheet> createState() => _ReorderBottomSheetState();
}

class _ReorderBottomSheetState extends State<ReorderBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final order = widget.order;
    final cart = context.watch<CartProvider>();
    final cartIsDirty = cart.cartItems.isNotEmpty;
    final dateLabel = order.placedAt != null
        ? DateFormat('d MMM y · HH:mm').format(order.placedAt!.toLocal())
        : '';
    final itemCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final itemsLabel = itemCount == 1 ? l.itemSingular : l.items;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.orderAgain,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _OrderTypeChip(orderTypeId: order.orderTypeId),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Destination / branch ──────────────────────────────────
            _DestinationRow(order: order),
            SizedBox(height: 16.h),

            // ── Item list ─────────────────────────────────────────────
            Text(
              '$itemCount $itemsLabel',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            ...order.items.map((i) => _ItemRow(item: i)),

            SizedBox(height: 12.h),
            Divider(height: 1, color: Colors.grey.shade300),
            SizedBox(height: 12.h),

            // ── Total ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.totalPrice,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${NumberFormat('#,##0').format(order.totalValue)} UZS',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            // ── Cart-replacement warning ──────────────────────────────
            if (cartIsDirty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18.w, color: const Color(0xFFB28704)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l.cartWillBeReplaced(cart.showQuantity()),
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF6B4F00)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // ── CTA ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEC700),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      const Color(0xFFFEC700).withOpacity(0.7),
                  disabledForegroundColor: Colors.black54,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: _isProcessing ? null : _handleReorder,
                child: _isProcessing
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    : Text(
                        l.reorder,
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReorder() async {
    final l = AppLocalizations.of(context);
    final controller = context.read<ReorderController>();
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isProcessing = true);

    // Let the spinner paint before doing the (potentially blocking) cart
    // materialization, so the user gets immediate feedback for the tap.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      final payload = controller.applyToCart(widget.order, cart);
      if (payload == null) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.reorderNoItemsAvailable),
        ));
        navigator.pop();
        return;
      }

      // Route through Cart first so users can see the upsell strip /
      // recommended add-ons before paying. Checkout reads the staged
      // prefill from the controller when the user proceeds.
      controller.stagePrefill(payload);
      navigator.pop(); // close sheet
      Navigator.pushNamed(context, '/cart');
    } catch (_) {
      // Unblock the button on unexpected failures so the user can retry.
      if (mounted) setState(() => _isProcessing = false);
      rethrow;
    }
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({required this.orderTypeId});
  final int orderTypeId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    late final String label;
    late final IconData icon;
    switch (orderTypeId) {
      case HistoryOrderType.delivery:
        label = l.delivery;
        icon = Icons.delivery_dining_outlined;
        break;
      case HistoryOrderType.selfPickup:
        label = l.selfPickup;
        icon = Icons.shopping_bag_outlined;
        break;
      case HistoryOrderType.carhop:
        label = l.carhop;
        icon = Icons.car_repair_outlined;
        break;
      case HistoryOrderType.dineIn:
        label = l.inRestaurant;
        icon = Icons.restaurant;
        break;
      default:
        label = '';
        icon = Icons.receipt_long_outlined;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEC700).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: Colors.black87),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.order});
  final LastOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDelivery = order.isDelivery;
    final text = isDelivery
        ? (order.deliveryAddress?.isNotEmpty == true
            ? order.deliveryAddress!
            : l.addressReconfirmAtCheckout)
        : (order.branchName ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDelivery ? Icons.location_on_outlined : Icons.storefront_outlined,
          size: 18.w,
          color: Colors.grey.shade700,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final LastOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEC700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              Text(
                '${NumberFormat('#,##0').format(item.actualPrice)} UZS',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          if (item.modifiers.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 32.w, top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.modifiers
                    .map((m) => Text(
                          '+ ${m.quantity} × ${m.name}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
