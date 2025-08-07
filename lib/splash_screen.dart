import 'package:flutter/material.dart';
import 'package:apploook/services/version_checker_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final VersionCheckerService _versionChecker = VersionCheckerService();
  bool _updateChecked = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
    
    // Check for updates after the splash screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Check for updates and show dialog if needed
  Future<void> _checkForUpdates() async {
    if (_updateChecked) return; // Prevent multiple checks
    
    _updateChecked = true;
    // Wait for a short delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if an update is required
    final bool updateRequired = await _versionChecker.checkForUpdates(context);
    
    // If no update is required, continue to the app
    if (!updateRequired && mounted) {
      // Continue with normal app flow
      // The update dialog will block the app if an update is required
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'images/logo-loook.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            // Custom branded loader
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, _) {
                          return Container(
                            width: constraints.maxWidth * _animationController.value,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFECC00),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Loading text with fade-in effect
            FadeTransition(
              opacity: _animationController,
              child: const Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
