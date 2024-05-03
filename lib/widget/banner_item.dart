import 'package:flutter/material.dart';

class BannerItem extends StatelessWidget {
  final String imageUrl;
  const BannerItem({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Customize container properties (padding, margin, etc.)
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
            child: Image.asset(
              imageUrl,
              fit: BoxFit.cover, // Adjust image fit if needed
            ),
          ),
        ],
      ),
    );
  }
}
