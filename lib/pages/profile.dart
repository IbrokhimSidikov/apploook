import 'package:apploook/cart_provider.dart';
import 'package:flutter/material.dart';
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

  // void _showDeleteConfirmationDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //           var cartProvider = Provider.of<CartProvider>(context);

  //       return AlertDialog(
  //         title: const Text('Confirm Deletion'),
  //         content: const Text('Are you sure you want to delete your account?'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               await _clearUserData();
  //               cartProvider.clearCart();
  //               Navigator.of(context).pop();
  //               Navigator.pushReplacementNamed(context, '/onboard');
  //             },
  //             child: const Text('Confirm', style: TextStyle(color: Colors.red)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 85,
            left: 25,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    //color: Color.fromARGB(255, 255, 215, 59),
                  ),
                  child: Image.asset(
                    'images/profile_icon.png', // Path to your SVG file
                    width: 50,
                    height: 50,
                    // Optional: apply color if needed
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientFirstName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      clientPhoneNumber,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            //menu list
            top: 200,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     SvgPicture.asset('images/inventory.svg'),
                //     const SizedBox(
                //       width: 25.0,
                //     ),
                //     const Text(
                //       'My Order History',
                //       style: TextStyle(fontSize: 18),
                //     ),
                //   ],
                // ),
                const SizedBox(
                  height: 40.0,
                ),
                // Row(
                //   children: [
                //     SvgPicture.asset('images/payment.svg'),
                //     const SizedBox(
                //       width: 25.0,
                //     ),
                //     const Text(
                //       'My Payment Card',
                //       style: TextStyle(fontSize: 18),
                //     ),
                //   ],
                // ),

                // Row(
                //   children: [
                //     SvgPicture.asset('images/settings.svg'),
                //     const SizedBox(
                //       width: 25.0,
                //     ),
                //     const Text(
                //       'Settings',
                //       style: TextStyle(fontSize: 18),
                //     ),
                //   ],
                // ),
                // const SizedBox(
                //   height: 40.0,
                // ),
                // const Text(
                //   'Feedback',
                //   style: TextStyle(fontSize: 18),
                // ),
                // const SizedBox(
                //   height: 40.0,
                // ),
                // const Text(
                //   'About',
                //   style: TextStyle(fontSize: 18),
                // ),
                // const SizedBox(
                //   height: 40.0,
                // ),
                // const Text(
                //   'Privacy Policy',
                //   style: TextStyle(fontSize: 18),
                // ),
                // const SizedBox(
                //   height: 150,
                // ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/notificationsView');
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.wallet_giftcard_outlined, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).orderHistory,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                GestureDetector(
                  onTap: () async {
                    bool? confirmLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            AppLocalizations.of(context).logout,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).logoutConfirmation,
                            style: TextStyle(fontSize: 16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
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
                                  fontSize: 16,
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
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    AppLocalizations.of(context).loggingOut,
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
                            content: Text('Error logging out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).logout,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                GestureDetector(
                  onTap: () async {
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            AppLocalizations.of(context).confirmDelete,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).confirmDialog,
                            style: TextStyle(fontSize: 16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
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
                                  fontSize: 16,
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
                      const Icon(Icons.delete, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).deleteAccount,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                // GestureDetector(
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (BuildContext context) {
                //         return AlertDialog(
                //           title: const Text("Call-Center"),
                //           content: Text(
                //               "Bizning call-markazimiz bilan \naloqaga chiqing \n$phoneNumber"),
                //           actions: [
                //             TextButton(
                //               onPressed: () {
                //                 Navigator.of(context).pop(); // Close the dialog
                //               },
                //               child: const Text(
                //                 "Cancel",
                //                 style: TextStyle(color: Colors.black),
                //               ),
                //             ),
                //             TextButton(
                //               onPressed: () {},
                //               child: const Text(
                //                 "Call",
                //                 style: TextStyle(
                //                     color: Color.fromARGB(255, 255, 215, 72)),
                //               ),
                //             ),
                //           ],
                //         );
                //       },
                //     );
                //   },
                //   child: SvgPicture.asset('images/lookSupport.svg'),
                // ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Version 1.5.1')],
        ),
      ),
    );
  }
}
