// ignore_for_file: deprecated_member_use

import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/models/view/map_screen.dart';
import 'package:apploook/widget/branch_locations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:apploook/cart_provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../widget/branch_data.dart';

class Checkout extends StatefulWidget {
  Checkout({
    Key? key,
  }) : super(key: key);

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  int _selectedIndex = 0;
  late double orderPrice = 0;
  String firstName = '';
  String phoneNumber = '';
  String clientComment = '';
  String clientCommentPhone = '';
  String commented = '';
  String orderType = '';
  late FirebaseRemoteConfig remoteConfig;
  bool _isRemoteConfigInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
    _loadPhoneNumber();
    _loadCustomerName();
  }

  Future<void> _initializeRemoteConfig() async {
    try {
      remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default value as a string
      // await remoteConfig.setDefaults({'chat_id': '-1002074915184'});

      bool updated = await remoteConfig.fetchAndActivate();
      _isRemoteConfigInitialized = true;

      print('Remote config updated: $updated');
      String currentChatId = remoteConfig.getString('chat_id');
      print('Current chat_id from Remote Config: $currentChatId');
    } catch (e) {
      print('Error initializing remote config: $e');
      _isRemoteConfigInitialized = false;
    }
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phoneNumber') ?? 'No number';
    });
  }

  num total = 0;

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Anonymous';
    });
  }

  void _updateCommented() {
    setState(() {
      commented = (clientComment.isNotEmpty ? clientComment + ', ' : '') +
          (clientCommentPhone.isNotEmpty
              ? 'Additional Number: ' + clientCommentPhone
              : '');
    });
  }

  bool _isProcessing = false;
  String? selectedAddress;
  String? selectedBranch;
  String? selectedOption;
  String? selectedCity;

  List<String> branches = [
    'Loook Yunusobod',
    'Loook Beruniy',
    'Loook Chilanzar',
    'Loook Maksim Gorkiy',
    'Loook Boulevard',
  ];
  List<String> city = [
    'Tashkent',
  ];

  String? _validatePayment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a payment method';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);

    orderPrice = cartProvider.getTotalPrice();

    List<String> orderItems = cartProvider.cartItems.map((item) {
      var itemTotal = item.quantity * item.product.price;
      total += itemTotal;

      return '${item.product.name}\n ${item.quantity} x ${NumberFormat('#,##0').format(item.product.price)} = ${NumberFormat('#,##0').format(item.quantity * item.product.price)} сум\n';
    }).toList();

    if (_selectedIndex == 0) {
      orderType = 'Delivery';
    } else {
      orderType = 'Self-Pickup';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 15.0,
                ),
                Text(
                  AppLocalizations.of(context).chooseOrderType,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: 170,
                ),
                // SvgPicture.asset('images/error_outline.svg'),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 0
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).delivery,
                    style:const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 1
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).selfPickup,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  // onPressed: () {},
                  onPressed: () => setState(() => _selectedIndex = 2),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      _selectedIndex == 2
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: const Text(
                    'CARHOP',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20.0,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 15, left: 15),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _selectedIndex == 0
                          ? AppLocalizations.of(context).yourDeliveryLocation
                          : _selectedIndex == 1
                              ? AppLocalizations.of(context).selfPickupTitle
                              : AppLocalizations.of(context).carhopService,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // DELIVERY
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            selectedAddress = result;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Container(
                          height: 140,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0xFFF1F2F7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .yourDeliveryLocation,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 20,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                          'images/close_black.svg'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0,
                                      right: 15.0,
                                      bottom: 15.0,
                                      top: 10),
                                  child: Text(
                                    selectedAddress ??
                                        AppLocalizations.of(context)
                                            .chooseYourLocation,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SELF-PICKUP
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Container(
                        height: 140,
                        width: 390,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color(0xFFF1F2F7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).chooseBranchToPick,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 20),
                              ),
                              const SizedBox(height: 10),
                              DropdownButton<String>(
                                value: selectedBranch,
                                hint: Text(
                                  AppLocalizations.of(context).selectBranch,
                                ),
                                dropdownColor:const Color(0xFFF1F2F7),
                                isExpanded: true,
                                items: branches.map((String branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch,
                                    child: Text(branch),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedBranch = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CARHOP
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: SizedBox(
                        height: _selectedIndex == 2 ? 390 : 140,
                        width: 390,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color:const Color(0xFFF1F2F7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset:const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  children: [
                                    // City Dropdown with 'X' button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButton<String>(
                                            value: selectedCity,
                                            hint: Text(AppLocalizations.of(context).selectRegion),
                                            isExpanded: true,
                                            dropdownColor: const Color(0xFFF1F2F7),
                                            items: city.map((String city) {
                                              return DropdownMenuItem<String>(
                                                value: city,
                                                child: Text(
                                                  city,
                                                  style:const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedCity = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                        if (selectedCity != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                selectedCity = null;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButton<String>(
                                            value: selectedBranch,
                                            hint: Text(AppLocalizations.of(context).selectBranch),
                                            isExpanded: true,
                                            dropdownColor:const Color(0xFFF1F2F7),
                                            items:
                                                branches.map((String branch) {
                                              return DropdownMenuItem<String>(
                                                value: branch,
                                                child: Text(
                                                  branch,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedBranch = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                        if (selectedBranch != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                selectedBranch = null;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 22.0,
                            ),
                             Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                AppLocalizations.of(context).carhopServiceBranchInfo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 15.0,),
                            Container(
                              height: 158,
                              width: 390,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2F7), 
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 
                                    20.0, right:15.0 ), 
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        color: Colors
                                            .transparent,
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: SvgPicture.asset(
                                              'images/carhopMetka.svg'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0,),
                                    Expanded(
                                      flex: 6,
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedBranch != null
                                                    ? "$selectedBranch - LOOOK"
                                                    : AppLocalizations.of(
                                                            context)
                                                        .selectBranch,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                       Color(0xFFff0000),
                                                ),
                                              ),
                                              if (selectedBranch != null) ...[
                                                const SizedBox(
                                                    height:
                                                        5.0), 
                                                Text(
                                                  BranchData.getBranchAddress(
                                                      selectedBranch), 
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color:  Color(0xff5B5B5B),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 15.0,),
                                              Text(
                                                '${AppLocalizations.of(context).openingHours} 9:00-00:00',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.0,
                                                ),
                                              ),
                                              const SizedBox(height: 15.0,),
                                              Row(
                                                children: [
                                                  SvgPicture.asset(
                                                      'images/mapPointer.svg'),
                                                  const SizedBox(
                                                    width: 15.0,
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      BranchLocations.openMap(
                                                          selectedBranch);
                                                    },
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .viewInMap,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF1C90E1),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        decoration: TextDecoration
                                                            .underline, // To indicate it's clickable
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                AppLocalizations.of(context).carDetails,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 40.0,
            ),            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD9D9D9), // Shadow color
                      offset: Offset(0, 7), // Offset in x and y direction
                      blurRadius: 10.0, // Spread radius
                      spreadRadius: 2.0, // Blur radius
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).orderPrice} :',
                            style:const TextStyle(fontSize: 16),
                          ),
                          Text(
                              '${NumberFormat('#,##0').format(orderPrice)} UZS'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).deliveryPrice} :',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(AppLocalizations.of(context).unknown),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).totalPrice} :',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                              '${NumberFormat('#,##0').format(orderPrice)} UZS'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).paymentMethod,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                value: selectedOption,
                items: [
                  DropdownMenuItem<String>(
                    value: 'Cash',
                    child: Row(
                      children: [
                        const Icon(Icons.money, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context).cash),
                      ],
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Card',
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context).card),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).additionalNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Container(
                    height: 48,
                    width: 390,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Fixed country code widget
                        const SizedBox(
                          width: 15.0,
                        ),
                        const Text(
                          '+998',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context).numberHintText,
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Allows only digits
                              LengthLimitingTextInputFormatter(
                                  9), // Limits the input to 9 digits
                            ],
                            onChanged: (value) {
                              clientCommentPhone = value;
                              _updateCommented();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 40.0,
                  ),
                  Text(
                    AppLocalizations.of(context).comments,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Container(
                    height: 100,
                    width: 390,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          clientComment = value;
                          _updateCommented();
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 50.0,
            ),
            ElevatedButton(
              onPressed: (_selectedIndex == 0
                      ? selectedAddress != null &&
                          selectedOption != null &&
                          !_isProcessing
                      : selectedBranch != null &&
                          selectedOption != null &&
                          !_isProcessing)
                  ? () async {
                      setState(() {
                        _isProcessing = true; // Start processing
                      });

                      try {
                        if (_selectedIndex == 0) {
                          // Send order to Telegram
                          await sendOrderToTelegram(
                            selectedAddress, // address
                            "Неизвестно", // branchName
                            firstName, // name
                            phoneNumber, // phone
                            selectedOption!, // paymentType
                            commented,
                            orderItems, // orderItems
                            orderPrice, // total
                            cartProvider.showLat(), // latitude
                            cartProvider.showLong(), // longitude
                            orderType,
                            cartProvider,
                          );
                        } else if (_selectedIndex == 1) {
                          await sendOrderToTelegram(
                            "Неизвестно", // address
                            selectedBranch!, // branchName
                            firstName, // name
                            phoneNumber, // phone
                            selectedOption!, // paymentType
                            commented,
                            orderItems, // orderItems
                            orderPrice, // total
                            41.313798749076454, // latitude ,
                            69.24407311805851, // longitude
                            orderType,
                            cartProvider,
                          );
                        }
                        // Show success message
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title:
                                Text(AppLocalizations.of(context).orderSuccess),
                            content: Text(AppLocalizations.of(context)
                                .orderSuccessSubTitle),
                            contentPadding:
                                EdgeInsets.only(top: 30, left: 30, right: 30),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pushReplacementNamed(
                                      context, '/homeNew');
                                },
                                child: Text(
                                  'OK',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        // Handle error
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Order Error'),
                            content: Text(
                                'Failed to place your order. Please try again later.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } finally {
                        setState(() {
                          _isProcessing = false; // Stop processing
                        });
                      }
                    }
                  : null, // Disable button if address is not selected
              style: ButtonStyle(
                backgroundColor: (_selectedIndex == 0
                        ? selectedAddress != null && selectedOption != null
                        : selectedBranch != null && selectedOption != null)
                    ? WidgetStateProperty.all<Color>(const Color(0xffFEC700))
                    : WidgetStateProperty.all<Color>(
                        const Color(0xFFCCCCCC)), // Change color when disabled
              ),
              child: _isProcessing
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 125.0),
                      child: Text(
                        AppLocalizations.of(context).order,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
            const SizedBox(
              height: 50.0,
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context).checkout,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const Cart()));
        },
        child: SizedBox(
          height: 25,
          width: 25,
          child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
        ),
      ),
    );
  }

  Future<String> getChatId() async {
    try {
      if (!_isRemoteConfigInitialized) {
        await _initializeRemoteConfig();
      }

      String chatId = remoteConfig.getString('chat_id');
      if (chatId.isEmpty) {
        print('Using default chat_id as Remote Config value was empty');
        return '-1002074915184';
      }

      print('Retrieved chat_id from Remote Config: $chatId');
      return chatId;
    } catch (e) {
      print('Error getting chat_id: $e');
      return '-1002074915184';
    }
  }

  Future<void> sendOrderToTelegram(
      String? address,
      String branchName,
      String name,
      String phone,
      String paymentType,
      String comment,
      List orderItems,
      double total,
      double latitude,
      double longitude,
      String orderType,
      CartProvider cartProvider) async {
    try {
      final orderDetails = "Адрес: $address\n" +
          "Филиал: $branchName\n" +
          "Имя: $name\n" +
          "Тел: $phone\n" +
          "Тип платежа: $paymentType\n\n" +
          "Тип zakaza: $orderType\n\n" +
          "Заметка: ${comment.isEmpty ? 'Нет заметки' : comment}\n\n" +
          "🛒 <b>Корзина:</b>\n${orderItems.join("\n")}\n\n" +
          "<b>Итого:</b> ${NumberFormat('#,##0').format(total).toString()} сум\n\n" +
          "-----------------------\n" +
          "Источник: Mobile App\n";

      final encodedOrderDetails = Uri.encodeQueryComponent(orderDetails);

      String chatId = await getChatId();
      print("Using chatId: $chatId");

      final telegramDebUrl =
          "https://api.sievesapp.com/v1/public/make-post?chat_id=$chatId&text=$encodedOrderDetails&latitude=$latitude&longitude=$longitude";

      final response = await http.get(
        Uri.parse(telegramDebUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode != 200) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send order');
      } else {
        print("Order sent successfully! Response: ${response.body}");
        cartProvider.clearCart();
      }
    } catch (e) {
      print('Error sending order: $e');
      rethrow;
    }
  }
}
