import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(),
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
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.fill,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
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
