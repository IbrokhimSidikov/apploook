import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/providers/product_configuration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final _priceFormat = NumberFormat('#,##0');

// ── Design tokens (mirrors the product details page) ────────────────────────
const _kPrimary = AppColors.cxFEC700;
const _kStepperBg = Color(0xFFD9D9D9);
const _kTextSecondary = Color(0xFFB0B0B0);
const _kTextBody = Color(0xFF5B5B5B);
const _kBorder = Color(0xFFE6E7EC);
const _kError = AppColors.cxC62828;
const _kFont = 'Poppins';

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
      margin: EdgeInsets.only(bottom: 24.h),
      // The error outline is drawn as an inset ring so the group's options stay
      // on the same grid whether or not it is showing a validation error.
      padding: EdgeInsets.all(hasError ? 12.w : 0),
      decoration: hasError
          ? BoxDecoration(
              color: _kError.withValues(alpha: 0.04),
              border: Border.all(color: _kError, width: 1.5),
              borderRadius: BorderRadius.circular(16.r),
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
                    fontFamily: _kFont,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.2,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: _RequirementBadge(
                  label: group.isRequired ? l10n.required : l10n.optional,
                  isRequired: group.isRequired,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              if (limitsLabel != null)
                Expanded(
                  child: Text(
                    limitsLabel,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: _kTextBody,
                    ),
                  ),
                )
              else
                const Spacer(),
              SizedBox(width: 8.w),
              Text(
                '$selectedCount/${group.effectiveMaxSelected}',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: hasError ? _kError : _kTextSecondary,
                ),
              ),
            ],
          ),
          if (hasError)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                error.isBelowMinimum
                    ? l10n.chooseAtLeast(group.minSelectedModifiers)
                    : l10n.chooseUpTo(group.effectiveMaxSelected),
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: _kError,
                ),
              ),
            ),
          SizedBox(height: 12.h),
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
    final showStepper = isSelected && modifier.supportsQuantity;

    final IconData icon;
    if (isSingleChoice) {
      icon =
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    } else {
      icon = isSelected
          ? Icons.check_box_rounded
          : Icons.check_box_outline_blank_rounded;
    }

    return Opacity(
      opacity: isLocked ? 0.4 : 1,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Material(
          color: isSelected ? _kPrimary.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                isLocked ? null : () => controller.toggleModifier(group, modifier),
            child: Container(
              constraints: BoxConstraints(minHeight: 56.h),
              padding: EdgeInsets.fromLTRB(14.w, 10.h, showStepper ? 8.w : 14.w, 10.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _kPrimary : _kBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22.sp,
                    color: isSelected ? _kPrimary : _kTextSecondary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modifier.name,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 15.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            height: 1.3,
                            color: Colors.black,
                          ),
                        ),
                        if (modifier.price > 0) ...[
                          SizedBox(height: 2.h),
                          Text(
                            '+${_priceFormat.format(modifier.price)} UZS',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: _kTextBody,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showStepper) ...[
                    SizedBox(width: 12.w),
                    _QuantityStepper(
                      value: quantity,
                      canIncrement: quantity < modifier.maxSelectedQuantity,
                      onIncrement: () =>
                          controller.incrementModifier(group, modifier),
                      onDecrement: () =>
                          controller.decrementModifier(group, modifier),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isRequired ? _kPrimary : const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1.2,
          color: isRequired ? Colors.black : _kTextBody,
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
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: _kStepperBg,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
          SizedBox(
            width: 28.w,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
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
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: Icon(
            icon,
            size: 18.sp,
            color: enabled ? Colors.black : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}
