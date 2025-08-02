import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:apploook/services/order_mode_service.dart';

class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? boxFit;
  final bool forceSquare;

  const CachedProductImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.boxFit,
    this.forceSquare = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double imageWidth = width ?? 140.0;
    double imageHeight = height ?? 140.0;
    BoxFit imageFit = boxFit ?? BoxFit.cover;

    try {
      final orderModeService = OrderModeService();
      final orderMode = orderModeService.currentMode;

      final bool isSquareMode =
          forceSquare || orderMode != OrderMode.deliveryTakeaway;

      if (width == null) {
        imageWidth = isSquareMode ? 500.0 : 600.0;
      }

      if (height == null) {
        imageHeight = isSquareMode ? 500.0 : 400.0;
      }

      // Log the image dimensions for debugging
      // print(
      //     'CachedProductImage: Mode=${orderMode}, Size=${imageWidth}x${imageHeight}');
    } catch (e) {
      // If order mode service fails, use default dimensions
      // print('CachedProductImage: Error getting order mode - $e');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: imageWidth,
        height: imageHeight,
        color: Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: imageFit,
          alignment: Alignment.center,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.grey[600],
              ),
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[600],
              size: 32.0,
            ),
          ),
          // Disable memory cache size constraints to allow proper rendering
          // The default caching mechanism will work fine
        ),
      ),
    );
  }
}
