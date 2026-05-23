import 'package:apploook/cart_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:apploook/consent_screen.dart';
import 'package:apploook/models/view/notifications_view.dart';
import 'package:apploook/pages/branches.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/splash_screen.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/pages/notification.dart';
import 'package:apploook/pages/onboard.dart';
import 'package:apploook/pages/order_tracking_page.dart';
import 'package:apploook/pages/unified_order_tracking_page.dart';
import 'package:apploook/pages/signin.dart';
import 'package:apploook/pages/simple_menu.dart';
import 'package:apploook/services/delivery_review_scheduler.dart';
import 'package:apploook/services/notification_service.dart';
import 'package:apploook/services/remote_config_service.dart';
import 'package:apploook/services/version_checker_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations_delegate.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'features/reorder/application/reorder_controller.dart';

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(MyLoaderApp());
}

class MyLoaderApp extends StatefulWidget {
  @override
  _MyLoaderAppState createState() => _MyLoaderAppState();
}

class _MyLoaderAppState extends State<MyLoaderApp> {
  bool? _acceptedPrivacyPolicy;
  bool _isLoading = true;
  final notificationProvider = NotificationProvider();
  final notificationService = NotificationService();
  final localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check if the privacy policy has been accepted
    // Default to false if not found (instead of null)
    final hasAccepted = prefs.getBool('accepted_privacy_policy') ?? false;
    print('Privacy policy acceptance status loaded: $hasAccepted');
    
    // Update the state with the loaded preference
    _acceptedPrivacyPolicy = hasAccepted;
    
    // Initialize locale provider to load saved language
    await localeProvider.initialize();
    
    CachedNetworkImage.logLevel = CacheManagerLogLevel.warning;
    // Limit Flutter's in-memory image cache: 50 MB total, max 100 images.
    // Because memCacheWidth/Height is now set on all CachedNetworkImage widgets,
    // each decoded image is small, so 50 MB / 100 entries is ample.
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 50;
    PaintingBinding.instance.imageCache.maximumSize = 100;

    // Initialize Firebase Remote Config service
    await RemoteConfigService().initialize();

    // Initialize notification service with provider
    notificationService.setProvider(notificationProvider);
    await notificationService.initialize();

    // Start delivery review scheduler (shows review prompt 5 min after delivery)
    DeliveryReviewScheduler().start(navigatorKey);

    // Only update UI after all initialization is complete
    if (mounted) {
      setState(() {
        _acceptedPrivacyPolicy = hasAccepted;
        _isLoading = false; // Finish loading
      });
    }
  }

  // Handle privacy policy acceptance and ensure it persists
  void _handlePrivacyPolicyAcceptance() async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_privacy_policy', true);
    
    // Update state
    if (mounted) {
      setState(() {
        _acceptedPrivacyPolicy = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider(create: (_) => ReorderController()),
      ],
      // Show elegant branded splash screen while initializing
      child: _isLoading 
          ? MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'Poppins',
                useMaterial3: true,
              ),
              home: const SplashScreen(),
            )
          : _acceptedPrivacyPolicy == true
              ? const MyApp()
              : ConsentScreen(onAccept: () async {
                // Handle privacy policy acceptance
                _handlePrivacyPolicyAcceptance();
                
                // Wait a moment to ensure the preference is saved
                await Future.delayed(const Duration(milliseconds: 100));
                
                // Then run the app with the updated state
                if (mounted) {
                  runApp(
                    MultiProvider(
                      providers: [
                        ChangeNotifierProvider(create: (_) => CartProvider()),
                        ChangeNotifierProvider.value(value: localeProvider),
                        ChangeNotifierProvider.value(value: notificationProvider),
                      ],
                      child: const MyApp(),
                    ),
                  );
                }
              }),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final VersionCheckerService _versionChecker = VersionCheckerService();
  String? _initialRoute;
  bool _isCheckingRoute = true;
  
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }
  
  Future<void> _determineInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if onboarding has been completed
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    
    if (hasCompletedOnboarding) {
      // Check if user is signed in
      final phoneNumber = prefs.getString('phoneNumber');
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        _initialRoute = '/homeNew';
      } else {
        _initialRoute = '/signin';
      }
    } else {
      _initialRoute = '/onboard';
    }
    
    if (mounted) {
      setState(() {
        _isCheckingRoute = false;
      });
      
      // Check for updates after the route is determined and UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }
  }
  
  Future<void> _checkForUpdates() async {
    // Add a small delay to ensure the navigator is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Check if an update is required
      await _versionChecker.checkForUpdates(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRoute) {
      // Show a simple loading indicator while determining route
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'LOOOK MOBILE',
          theme: ThemeData(
            fontFamily: 'Poppins',
            useMaterial3: true,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Poppins'),
              bodyMedium: TextStyle(fontFamily: 'Poppins'),
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
            ),
          ).copyWith(platform: TargetPlatform.android),
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('uz'),
            Locale('ru'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: _initialRoute,
          routes: {
            '/homeNew': (context) => const HomeNew(),
            '/signin': (context) => const SignIn(),
            '/cart': (context) => const Cart(),
            '/checkout': (context) => Checkout(),
            '/onboard': (context) => const Onboard(),
            '/notificationsView': (context) => const NotificationsView(),
            '/notification': (context) => const NotificationPage(),
            '/simpleMenu': (context) => const SimpleMenuPage(),
            '/orderTracking': (context) => const OrderTrackingPage(),
            '/unifiedOrderTracking': (context) =>
                const UnifiedOrderTrackingPage(),
            '/branches': (context) => const Branches(),
          },
        );
      },
      ),
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
            Navigator.pushNamed(context, snapshot.data!);
          });
          return Scaffold();
        }
      },
    );
  }
}
