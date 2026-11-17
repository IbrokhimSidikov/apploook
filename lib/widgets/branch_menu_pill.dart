import 'package:apploook/config/branch_config.dart';
import 'package:apploook/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shows which branch the home menu belongs to. The menu (prices, stop-list)
/// differs per branch and the branch is picked from the user's location, so
/// the user should see which one they got.
///
/// Sized to sit in the app bar next to the crystal balance pill (same
/// height, same pill shape).
///
/// [branchName] is the BranchConfigs key (e.g. "Ganga", "Yangiyol Loook");
/// null while the nearest branch is still being resolved.
class BranchMenuPill extends StatelessWidget {
  const BranchMenuPill({super.key, required this.branchName});

  final String? branchName;

  /// "Yangiyol Loook" -> "Yangiyol", "City Boulevard Loook" -> "City Boulevard",
  /// "GANGA" -> "Ganga". The brand is shown separately, so it is dropped here.
  static String displayName(String key) {
    final cleaned = key
        .replaceAll(RegExp(r'chicken\s+by', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bloook\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// "Chicken by Loook" for Ganga / Sergeli, "Loook" for the rest
  /// (BranchConfig.brand). Unknown branches default to "Loook".
  static String brandFor(String key) {
    final resolved = BranchConfigs.resolveKey(key);
    return (resolved != null ? BranchConfigs.configs[resolved]?.brand : null) ??
        BranchConfig.brandLoook;
  }

  @override
  Widget build(BuildContext context) {
    final name = branchName;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: name == null || name.isEmpty || name == 'Test'
          ? _placeholder()
          : _pill(brandFor(name), displayName(name)),
    );
  }

  Widget _pill(String brand, String name) {
    return Container(
      key: ValueKey('$brand/$name'),
      // Same outer height as CashbackBadge: 24.w icon + 4.h top/bottom.
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 10.w, 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE4E5EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFEC700),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 14.w,
              color: AppColors.cx0B0B0B,
            ),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand tag: "LOOOK" / "CHICKEN BY LOOOK".
                Text(
                  brand.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.sp,
                    height: 1.1,
                    letterSpacing: 0.4,
                    color: const Color(0xFF8A8B93),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.15,
                    color: AppColors.cx0B0B0B,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Shimmer.fromColors(
      key: const ValueKey('branch-pill-loading'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 84.w,
        height: 24.w + 8.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }
}
