import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../application/reorder_controller.dart';
import 'reorder_list_sheet.dart';

/// Floating "Reorder last order" pill, designed to sit on the right side of
/// the home screen — mirror to the existing cart pill on the left.
/// Only renders when the controller has a last order to offer.
class ReorderFab extends StatelessWidget {
  const ReorderFab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReorderController>();
    final order = controller.lastOrder;
    if (order == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50.r),
          onTap: () => _openSheet(context, controller),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay_rounded,
                    color: const Color(0xFFFEC700), size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  'Reorder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, ReorderController controller) {
    ReorderListSheet.open(context, controller.lastOrders);
  }
}
