import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/crystal_shop/presentation/crystal_theme.dart';
import '../l10n/app_localizations.dart';

/// "Pay with crystals" selector for a cart row and the details page.
///
/// A tappable pill rather than a Switch: it has to fit beside the quantity
/// stepper on a cart row, and it carries the crystal price so the customer
/// sees what the choice costs before making it. A null [onChanged] means the
/// choice is locked (crystal-only product): the pill stays selected and only
/// states the fact.
class CrystalPayToggle extends StatelessWidget {
  const CrystalPayToggle({
    super.key,
    required this.crystalPrice,
    required this.value,
    this.onChanged,
    this.crystalOnly = false,
  });

  final int crystalPrice;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool crystalOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locked = onChanged == null;
    final selected = value || locked;
    final tint = selected ? CrystalTheme.lilacText : CrystalTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crystalOnly) ...[
          const CrystalOnlyBadge(),
          SizedBox(height: 6.h),
        ],
        Material(
          color: selected ? CrystalTheme.lilac : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: selected ? CrystalTheme.violetBright : CrystalTheme.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: locked ? null : () => onChanged!(!value),
            child: Padding(
              padding: EdgeInsets.fromLTRB(9.w, 6.h, 10.w, 6.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(CrystalTheme.asset,
                      width: 19.w, height: 19.w),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      '${l.payWithCrystals} · ${l.crystalsAmount(crystalPrice)}',
                      style: TextStyle(
                        fontFamily: CrystalTheme.font,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: tint,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    locked
                        ? Icons.lock_rounded
                        : selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                    size: 16.sp,
                    color: selected
                        ? CrystalTheme.violetBright
                        : CrystalTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small violet "Crystals only" marker.
class CrystalOnlyBadge extends StatelessWidget {
  const CrystalOnlyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: CrystalTheme.violet,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        AppLocalizations.of(context).crystalOnly,
        style: TextStyle(
          fontFamily: CrystalTheme.font,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// What a signed-out customer sees on a crystal-only product instead of the
/// toggle: the marker plus the reason they cannot buy it yet.
class CrystalOnlySignInHint extends StatelessWidget {
  const CrystalOnlySignInHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const CrystalOnlyBadge(),
        SizedBox(height: 4.h),
        Text(
          AppLocalizations.of(context).crystalOnlyNeedsSignIn,
          style: TextStyle(
            fontFamily: CrystalTheme.font,
            fontSize: 11.sp,
            height: 1.3,
            color: CrystalTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Crystal price in place of a money price: icon plus "119 crystals".
class CrystalPriceText extends StatelessWidget {
  const CrystalPriceText({super.key, required this.crystals, this.fontSize});

  final int crystals;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? 13.sp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(CrystalTheme.asset,
            width: size * 1.35, height: size * 1.35),
        SizedBox(width: 4.w),
        Text(
          AppLocalizations.of(context).crystalsAmount(crystals),
          style: TextStyle(
            fontFamily: CrystalTheme.font,
            fontSize: size,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: CrystalTheme.lilacText,
          ),
        ),
      ],
    );
  }
}
