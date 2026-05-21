import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'banner_item.dart';

class BannerCarouselWidget extends StatelessWidget {
  final List<BannerItem> banners;
  final bool isLoading;

  const BannerCarouselWidget({
    Key? key,
    required this.banners,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
      ),
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 0.0),
              decoration: BoxDecoration(
                color: banner.boxColor.withOpacity(0.0),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: _buildBannerImage(banner.imagePath),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildBannerImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      // Banners are displayed at ~160 logical px tall.
      // Cap decode resolution at 800×320 physical px (≈400×160 logical @ 2×)
      // to prevent multi-MB raw pixel buffers during carousel auto-play.
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.fill,
        memCacheWidth: 800,
        memCacheHeight: 320,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error_outline, size: 40, color: Colors.red),
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.fill,
      );
    }
  }
}
