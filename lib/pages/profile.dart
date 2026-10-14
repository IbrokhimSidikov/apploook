import 'package:apploook/cart_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/loyalty_service.dart';
import '../providers/loyalty_provider.dart';
import '../widgets/loyalty_profile_card.dart';
import '../widgets/announcement_story_dialog.dart';
import '../widgets/confirm_action_sheet.dart';

/// Profile tab. Used to be the home screen's side drawer; it is now a full
/// page behind the fourth item of the bottom tab bar, so the layout scrolls
/// instead of relying on fixed offsets.
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String clientFirstName = '';
  String clientPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    _loadCustomerName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LoyaltyProvider>().refresh(silent: true);
    });
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final individualId = prefs.getInt('individual_id');

    if (individualId != null) {
      // Call logout API
      final authService = AuthService();
      await authService.logout(individualId.toString());
    }

    // Revoke the loyalty session server-side too. prefs.clear() below would
    // drop the local token either way, but leaving a live session on the
    // server means a copied token keeps working after the customer logs out.
    await LoyaltyService().endSession();

    // Clear all preferences
    await prefs.clear();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      clientPhoneNumber = prefs.getString('phoneNumber') ?? 'No number';
    });
  }

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      clientFirstName = prefs.getString('firstName') ?? 'Anonymous';
    });
  }

  Future<void> _showAnnouncementDebugSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Announcement (debug)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only visible in debug builds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<({String? storedId, int count, int max})>(
                  future: AnnouncementStory.debugStatus(),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    final label = status == null
                        ? 'View count: …'
                        : 'Views this announcement: ${status.count} / ${status.max}';
                    return Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Preview now (uses current Remote Config)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await AnnouncementStory.preview(context);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Reset 'seen' for next launch"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await AnnouncementStory.resetSeen();
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Cleared. Announcement will trigger on next launch.",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a blocking spinner dialog while an account action runs.
  void _showProgressDialog(String label, {Color? color}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? Theme.of(context).primaryColor,
                  ),
                ),
                20.verticalSpace,
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final l = AppLocalizations.of(context);
    final cartProvider = context.read<CartProvider>();

    bool? confirmLogout = await showConfirmActionSheet(
      context,
      icon: Icons.logout_rounded,
      title: l.logout,
      message: l.logoutConfirmation,
      confirmLabel: l.confirm,
      cancelLabel: l.cancel,
    );
    if (confirmLogout != true || !mounted) return;

    _showProgressDialog(l.loggingOut);

    try {
      await _clearUserData();
      cartProvider.clearCart();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    final cartProvider = context.read<CartProvider>();

    bool? confirmDelete = await showConfirmActionSheet(
      context,
      icon: Icons.delete_outline_rounded,
      title: l.confirmDelete,
      message: l.confirmDialog,
      confirmLabel: l.delete,
      cancelLabel: l.cancel,
      destructive: true,
    );
    if (confirmDelete != true || !mounted) return;

    _showProgressDialog('Deleting account...', color: Colors.red);

    try {
      await _clearUserData();
      cartProvider.clearCart();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Inflated by the tab shell so the list clears the floating tab bar.
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomInset + 24.h),
          children: [
            Text(
              l.profile,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.cx0B0B0B,
              ),
            ),
            SizedBox(height: 16.h),

            // ── Customer header ───────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('images/profile_icon.png'),
                ),
                16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientFirstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        clientPhoneNumber,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            const LoyaltyProfileCard(),
            SizedBox(height: 20.h),

            // ── Main menu ─────────────────────────────────────────────────
            _ProfileSection(
              children: [
                ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: l.orderHistory,
                  route: '/unifiedOrderTracking',
                ),
                ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: l.branches,
                  route: '/branches',
                ),
                const LanguageMenuItem(),
                if (kDebugMode)
                  _ProfileTile(
                    icon: Icons.campaign_outlined,
                    title: 'Announcement (debug)',
                    onTap: () => _showAnnouncementDebugSheet(context),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Account actions ───────────────────────────────────────────
            _ProfileSection(
              children: [
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  title: l.logout,
                  onTap: _logout,
                ),
                _ProfileTile(
                  icon: Icons.delete_outline_rounded,
                  title: l.deleteAccount,
                  color: const Color(0xFFD32F2F),
                  onTap: _deleteAccount,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            const _VersionFooter(),
          ],
        ),
      ),
    );
  }
}

/// Rounded card that groups a run of [_ProfileTile]s with thin dividers.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 60.w,
                color: const Color(0xFFF0F0F0),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single row in a [_ProfileSection]: leading icon chip, title, and either
/// a custom [trailing] widget or a chevron.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Tints icon and title; used for the destructive delete row.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? AppColors.cx0B0B0B;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color != null
                    ? color!.withOpacity(0.08)
                    : const Color(0xFFF1F2F7),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.sp, color: foreground),
            ),
            12.horizontalSpace,
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22.sp,
                  color: Colors.grey[400],
                ),
          ],
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final label = info == null
            ? ''
            : 'Version ${info.version} (${info.buildNumber})';
        return Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        );
      },
    );
  }
}

class _LanguageOption {
  final String code;
  final String flag;
  final String label;

  const _LanguageOption(this.code, this.flag, this.label);
}

const List<_LanguageOption> _kLanguages = [
  _LanguageOption('uz', '\u{1F1FA}\u{1F1FF}', "O'zbekcha"),
  _LanguageOption('en', '\u{1F1EC}\u{1F1E7}', 'English'),
  _LanguageOption('ru', '\u{1F1F7}\u{1F1FA}', 'Русский'),
];

/// Language picker row for the profile menu. The selection is persisted
/// under `selected_language` so it survives a restart, same key the app has
/// always used.
class LanguageMenuItem extends StatelessWidget {
  const LanguageMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    final currentCode = context.watch<LocaleProvider>().locale.languageCode;

    return PopupMenuButton<String>(
      offset: Offset(0, 48.h),
      color: Colors.white,
      tooltip: AppLocalizations.of(context).chooseLanguage,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onSelected: (String newLocale) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', newLocale);
        if (!context.mounted) return;
        context.read<LocaleProvider>().setLocale(Locale(newLocale));
      },
      itemBuilder: (context) => [
        for (final language in _kLanguages)
          PopupMenuItem<String>(
            value: language.code,
            child: Row(
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(language.label),
                if (language.code == currentCode) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 18.sp),
                ],
              ],
            ),
          ),
      ],
      child: _ProfileTile(
        icon: Icons.language_outlined,
        title: AppLocalizations.of(context).language,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.cxFEC700,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentCode.toUpperCase(),
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu row that pushes a named route when tapped.
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: icon,
      title: title,
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
