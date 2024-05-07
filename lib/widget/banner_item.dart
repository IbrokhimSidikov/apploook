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
          imagePath: 'images/sale50offburgers.png',
          boxColor: Colors.yellow),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/sale50offburgers.png',
          boxColor: Colors.yellow),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/sale50offburgers.png',
          boxColor: Colors.yellow),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/sale50offburgers.png',
          boxColor: Colors.yellow),
    );
    banners.add(
      BannerItem(
          name: 'banner1',
          imagePath: 'images/sale50offburgers.png',
          boxColor: Colors.yellow),
    );

    return banners;
  }
}
