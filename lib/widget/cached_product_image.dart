import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

    // Use delivery mode dimensions (rectangular)
    if (width == null) {
      imageWidth = forceSquare ? 500.0 : 600.0;
    }

    if (height == null) {
      imageHeight = forceSquare ? 500.0 : 400.0;
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
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: imageWidth,
              height: imageHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
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
