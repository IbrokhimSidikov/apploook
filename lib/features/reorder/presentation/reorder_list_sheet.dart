import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widget/app_bottom_sheet.dart';
import '../domain/last_order.dart';
import 'reorder_bottom_sheet.dart';

/// Picker that lists the user's last few reorder-eligible orders. Selecting
/// one opens the existing [ReorderBottomSheet] detail/confirm flow unchanged.
class ReorderListSheet extends StatelessWidget {
  const ReorderListSheet({super.key, required this.orders});

  final List<LastOrder> orders;

  /// Opens the right entry point for the reorder flow: the picker when there
  /// are several past orders, or the detail sheet directly when there's only
  /// one (no point asking the user to pick from a list of one).
  static void open(BuildContext context, List<LastOrder> orders) {
    if (orders.isEmpty) return;
    if (orders.length == 1) {
      AppBottomSheet.show(
        context: context,
        child: ReorderBottomSheet(order: orders.first),
      );
      return;
    }
    AppBottomSheet.show(
      context: context,
      child: ReorderListSheet(orders: orders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.orderAgain,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l.reorderSelectPrompt,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            ...orders.map(
              (o) => _OrderCard(
                order: o,
                onTap: () => _select(context, o),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, LastOrder order) {
    // Close the picker, then open the existing detail/confirm sheet so the
    // reorder logic downstream is identical to the single-order entry point.
    Navigator.of(context).pop();
    AppBottomSheet.show(
      context: context,
      child: ReorderBottomSheet(order: order),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final LastOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateLabel = order.placedAt != null
        ? DateFormat('d MMM y · HH:mm').format(order.placedAt!.toLocal())
        : '';
    final itemCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final itemsLabel = itemCount == 1 ? l.itemSingular : l.items;
    final preview = order.items.map((i) => i.name).where((n) => n.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _OrderTypeChip(orderTypeId: order.orderTypeId),
                          if (dateLabel.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        preview.join(', '),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '$itemCount $itemsLabel · '
                        '${NumberFormat('#,##0').format(order.totalValue)} UZS',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22.w,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEC700).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: Colors.black87),
          if (label.isNotEmpty) ...[
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
