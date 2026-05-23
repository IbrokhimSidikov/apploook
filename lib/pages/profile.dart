import 'package:apploook/cart_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../widgets/announcement_story_dialog.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String phoneNumber = '71-207-207-0';
  String clientFirstName = '';
  String clientPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    _loadCustomerName();
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final individualId = prefs.getInt('individual_id');

    if (individualId != null) {
      // Call logout API
      final authService = AuthService();
      await authService.logout(individualId.toString());
    }

    // Clear all preferences
    await prefs.clear();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      clientPhoneNumber = prefs.getString('phoneNumber') ?? 'No number';
    });
  }

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
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
  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 85.h,
            left: 25.w,
            child: Row(
              children: [
                Container(
                  padding:
                    EdgeInsets.only(left: 5.w, top: 5.h),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    //color: Color.fromARGB(255, 255, 215, 59),
                  ),
                  child: Image.asset(
                    'images/profile_icon.png', // Path to your SVG file
                    width: 50.w,
                    height: 50.h,
                    // Optional: apply color if needed
                  ),
                ),
                20.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientFirstName,
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      clientPhoneNumber,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 200.h,
            left: 40.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                40.verticalSpace,
                ProfileMenuItem(
                  icon: Icons.wallet_giftcard_outlined,
                  title: AppLocalizations.of(context).orderHistory,
                  route: '/unifiedOrderTracking',
                ),
                40.verticalSpace,
                ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: AppLocalizations.of(context).branches,
                  route: '/branches',
                ),
                if (kDebugMode) ...[
                  40.verticalSpace,
                  GestureDetector(
                    onTap: () => _showAnnouncementDebugSheet(context),
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined, size: 24.sp),
                        10.horizontalSpace,
                        Text(
                          'Announcement (debug)',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ],
                    ),
                  ),
                ],
                40.verticalSpace,
                GestureDetector(
                  onTap: () async {
                    bool? confirmLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          title: Text(
                            AppLocalizations.of(context).logout,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).logoutConfirmation,
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                AppLocalizations.of(context).confirm,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmLogout == true) {
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
                              padding: EdgeInsets.symmetric(
                                vertical: 20.h,
                                horizontal: 30.w,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  20.verticalSpace,
                                  Text(
                                    AppLocalizations.of(context).loggingOut,
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

                      try {
                        await _clearUserData();
                        cartProvider.clearCart();
                        Navigator.of(context).pop();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/onboard',
                          (route) => false,
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error logging out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 24.sp),
                      10.horizontalSpace,
                      Text(
                        AppLocalizations.of(context).logout,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ],
                  ),
                ),
                40.verticalSpace,
                GestureDetector(
                  onTap: () async {
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          title: Text(
                            AppLocalizations.of(context).confirmDelete,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).confirmDialog,
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                AppLocalizations.of(context).delete,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 30,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Deleting account...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      try {
                        await _clearUserData();
                        cartProvider.clearCart();
                        Navigator.of(context).pop();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/onboard',
                          (route) => false,
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting account: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 24.sp),
                      10.horizontalSpace,
                      Text(
                        AppLocalizations.of(context).deleteAccount,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Version 3.0.0')],
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Row(
        children: [
          Icon(icon, size: 24.sp),
          10.horizontalSpace,
          Text(
            title,
            style: TextStyle(fontSize: 18.sp),
          ),
        ],
      ),
    );
  }
}