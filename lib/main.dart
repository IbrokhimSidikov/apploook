
import 'package:apploook/api/firebase_api.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/models/view/notifications_view.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/pages/onboard.dart';
import 'package:apploook/pages/signin.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseApi().initNotifications();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("FCMToken $fcmToken");
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? acceptedPrivacyPolicy = prefs.getBool('accepted_privacy_policy');
  CachedNetworkImage.logLevel = CacheManagerLogLevel.warning;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100;

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: acceptedPrivacyPolicy == true
          ? const MyApp()
          : ConsentScreen(onAccept: () {
              runApp(
                ChangeNotifierProvider(
                  create: (context) => CartProvider(),
                  child: const MyApp(),
                ),
              );
            }),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          displayLarge: TextStyle(fontFamily: 'Poppins'),
          displayMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: InitialScreen(),
      routes: {
        '/homeNew': (context) => HomeNew(),
        '/signin': (context) => SignIn(),
        '/cart': (context) => Cart(),
        '/checkout': (context) => Checkout(),
        '/onboard': (context) => Onboard(),
        '/notificationsView': (context) => NotificationsView(),
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      return '/homeNew';
    } else {
      return '/onboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, snapshot.data!);
          });
          return Scaffold();
        }
      },
    );
  }
}

class ConsentScreen extends StatelessWidget {
  final Function onAccept;

  ConsentScreen({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Privacy Policy'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Introduction\n\n'
                    'Our privacy policy will help you understand what information we collect at Loook, how Loook uses it, and what choices you have. Loook built the Loook app as a free app. This SERVICE is provided by Loook at no cost and is intended for use as is. If you choose to use our Service, then you agree to the collection and use of information in relation with this policy. The Personal Information that we collect are used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy. The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible in our website, unless otherwise defined in this Privacy Policy.\n\n'
                    'Information Collection and Use\n\n'
                    'For a better experience while using our Service, we may require you to provide us with certain personally identifiable information, including but not limited to users name, email address, gender, location, pictures. The information that we request will be retained by us and used as described in this privacy policy. The app does use third party services that may collect information used to identify you.\n\n'
                    'Cookies\n\n'
                    'Cookies are files with small amount of data that is commonly used an anonymous unique identifier. These are sent to your browser from the website that you visit and are stored on your devices’s internal memory.\n\n'
                    'This Services does not uses these “cookies” explicitly. However, the app may use third party code and libraries that use “cookies” to collection information and to improve their services. You have the option to either accept or refuse these cookies, and know when a cookie is being sent to your device. If you choose to refuse our cookies, you may not be able to use some portions of this Service.\n\n'
                    'Location Information\n\n'
                    'Some of the services may use location information transmitted from users\' mobile phones. We only use this information within the scope necessary for the designated service.\n\n'
                    'Device Information\n\n'
                    'We collect information from your device in some cases. The information will be utilized for the provision of better service and to prevent fraudulent acts. Additionally, such information will not include that which will identify the individual user.\n\n'
                    'Service Providers\n\n'
                    'We may employ third-party companies and individuals due to the following reasons:\n\n'
                    '- To facilitate our Service;\n'
                    '- To provide the Service on our behalf;\n'
                    '- To perform Service-related services; or\n'
                    '- To assist us in analyzing how our Service is used.\n\n'
                    'We want to inform users of this Service that these third parties have access to your Personal Information. The reason is to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.\n\n'
                    'Security\n\n'
                    'We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.\n\n'
                    'Children’s Privacy\n\n'
                    'This Services do not address anyone under the age of 13. We do not knowingly collect personal identifiable information from children under 13. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions.\n\n'
                    'Changes to This Privacy Policy\n\n'
                    'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately, after they are posted on this page.\n\n'
                    'Contact Us\n\n'
                    'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.\n'
                    'Contact Information:\n'
                    'Email: loook.uz.tech@gmail.com',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle decline logic here, e.g., close the app
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(140, 40),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('accepted_privacy_policy', true);
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFECC00),
                      fixedSize: Size(140, 40),
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
