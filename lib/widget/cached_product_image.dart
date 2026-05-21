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
    final dpr = MediaQuery.of(context).devicePixelRatio;
    BoxFit imageFit = boxFit ?? BoxFit.cover;

    // Compute mem-cache width from the explicit width param (or a sensible
    // fallback). Only memCacheWidth is set — Flutter derives the height
    // proportionally so the image aspect ratio is always preserved during
    // decode, preventing stretched/distorted pixels.
    final double displayWidth = width ?? (forceSquare ? 140.0 : 200.0);
    final int memW = (displayWidth * dpr).ceil();

    // Use SizedBox.expand so the parent (e.g. AspectRatio in homenew.dart)
    // controls the actual box size — the image never fights its parent's
    // constraints and always fills with the correct 3:2 (or whatever) ratio.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: Colors.grey[200]!,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: imageFit,
            alignment: Alignment.center,
            memCacheWidth: memW,
            // memCacheHeight is intentionally omitted — height is derived
            // from the image's natural aspect ratio, preventing distortion.
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
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
          ),
        ),
      ),
    );
  }
}
