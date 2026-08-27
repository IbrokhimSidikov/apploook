import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/providers/product_configuration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final _priceFormat = NumberFormat('#,##0');

/// One modifier group on the product details page: header with the group's
/// selection rules, an optional validation message, and its options.
///
/// Behaviour is derived purely from the group's limits, never from its name:
/// single-choice groups render as radios, multi-choice groups as checkboxes,
/// and modifiers with `maxAmount > 1` get a quantity stepper once selected.
class ModifierGroupWidget extends StatelessWidget {
  final ModifierGroup group;
  final ProductConfigurationController controller;

  const ModifierGroupWidget({
    super.key,
    required this.group,
    required this.controller,
  });

  String? _limitsLabel(AppLocalizations l10n) {
    final min = group.minSelectedModifiers;
    final max = group.effectiveMaxSelected;
    if (min == max) return l10n.chooseExactly(min);
    if (min == 0) return max > 1 ? l10n.chooseUpTo(max) : null;
    return l10n.chooseBetween(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = controller.shownErrorFor(group.id);
    final hasError = error != null;
    final limitsLabel = _limitsLabel(l10n);
    final selectedCount = controller.selectedCount(group.id);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(hasError ? 8.w : 0),
      decoration: hasError
          ? BoxDecoration(
              border: Border.all(color: AppColors.cxC62828, width: 1.5),
              borderRadius: BorderRadius.circular(12.r),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _RequirementBadge(
                label: group.isRequired ? l10n.required : l10n.optional,
                isRequired: group.isRequired,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              if (limitsLabel != null)
                Text(
                  limitsLabel,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              const Spacer(),
              Text(
                '$selectedCount/${group.effectiveMaxSelected}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: hasError ? AppColors.cxC62828 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (hasError)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                error.isBelowMinimum
                    ? l10n.chooseAtLeast(group.minSelectedModifiers)
                    : l10n.chooseUpTo(group.effectiveMaxSelected),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.cxC62828,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          ...group.modifiers.map(
            (modifier) => ModifierOptionTile(
              group: group,
              modifier: modifier,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single selectable modifier row with radio/checkbox affordance, optional
/// surcharge and a quantity stepper when the modifier allows more than one.
class ModifierOptionTile extends StatelessWidget {
  final ModifierGroup group;
  final Modifier modifier;
  final ProductConfigurationController controller;

  const ModifierOptionTile({
    super.key,
    required this.group,
    required this.modifier,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.isSelected(group.id, modifier.id);
    final isSingleChoice = group.effectiveMaxSelected == 1;
    // In multi-choice groups, lock unselected options once the max is hit so
    // the limit is visible rather than silently ignored on tap.
    final isLocked =
        !isSelected && !isSingleChoice && !controller.canSelectMore(group);
    final quantity = controller.quantityOf(group.id, modifier.id);

    final IconData icon;
    if (isSingleChoice) {
      icon = isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    } else {
      icon = isSelected ? Icons.check_box : Icons.check_box_outline_blank;
    }

    return Opacity(
      opacity: isLocked ? 0.45 : 1,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.cxFEC700 : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ListTile(
          dense: true,
          onTap: isLocked ? null : () => controller.toggleModifier(group, modifier),
          leading: Icon(
            icon,
            color: isSelected ? AppColors.cxFEC700 : Colors.grey,
          ),
          title: Text(
            modifier.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: modifier.price > 0
              ? Text(
                  '+${_priceFormat.format(modifier.price)} UZS',
                  style: const TextStyle(color: Colors.green),
                )
              : null,
          trailing: isSelected && modifier.supportsQuantity
              ? _QuantityStepper(
                  value: quantity,
                  canIncrement: quantity < modifier.maxSelectedQuantity,
                  onIncrement: () =>
                      controller.incrementModifier(group, modifier),
                  onDecrement: () =>
                      controller.decrementModifier(group, modifier),
                )
              : null,
        ),
      ),
    );
  }
}

class _RequirementBadge extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _RequirementBadge({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isRequired ? AppColors.cxFEC700 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: isRequired ? Colors.black : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.value,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(50.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              '$value',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(50.r),
        ),
        padding: EdgeInsets.all(2.w),
        child: Icon(
          icon,
          size: 18.sp,
          color: onTap == null ? Colors.grey : Colors.black,
        ),
      ),
    );
  }
}
