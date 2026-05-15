import 'package:apploook/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart'; // Import AuthService

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
          children: [Text('Version 2.8.0')],
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