import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:apploook/pages/onboard.dart';

class CustomLoader extends StatefulWidget {
  final String message;
  final String videoPath;
  final Widget nextScreen;
  final Duration delayDuration;

  const CustomLoader({
    Key? key,
    this.message = "Loading...",
    required this.videoPath,
    required this.nextScreen,
    this.delayDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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

      // Listen for the end of the video
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => widget.nextScreen),
            );
          }
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        // If there's an error, navigate to next screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFECC00)),
              ),
            ),
    );
  }
}
