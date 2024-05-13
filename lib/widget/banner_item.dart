import 'package:flutter/material.dart';

class BannerItem {
  String name;
  String imagePath;
  Color boxColor;

  BannerItem({
    required this.name,
    required this.imagePath,
    required this.boxColor,
  });

  static List<BannerItem> getBanners() {
    List<BannerItem> banners = [];

    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner2.png',
          boxColor: Colors.white),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner3.png',
          boxColor: Colors.white),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner4.png',
          boxColor: Colors.white),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner2.png',
          boxColor: Colors.white),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner3.png',
          boxColor: Colors.white),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/banner4.png',
          boxColor: Colors.white),
    );

    return banners;
  }
}
