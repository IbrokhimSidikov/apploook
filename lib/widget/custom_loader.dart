import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomLoader extends StatefulWidget {
  final String videoPath;
  final Widget nextScreen;
  final Duration delayDuration;

  const CustomLoader({
    Key? key,
    required this.videoPath,
    required this.nextScreen,
    this.delayDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isTransitioning = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    // Setup fade animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _controller.setLooping(false);
      _controller.play();

      // Wait for the video to finish, then start transition
      Future.delayed(widget.delayDuration, () {
        if (mounted) _startTransition();
      });
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) _startTransition();
    }
  }

  void _startTransition() {
    if (_isTransitioning) return;
    _isTransitioning = true;

    _animationController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          _isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFECC00)),
                  ),
                ),
          // Fade transition overlay
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(color: Colors.black), // Keeps it smooth
          ),
        ],
      ),
    );
  }
}
