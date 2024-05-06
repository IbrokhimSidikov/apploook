import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String imagePath;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.imagePath,
    required this.boxColor,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/IMG_3311.png',
        boxColor: const Color.fromARGB(0, 210, 16, 16),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/pizza_icon.png',
        boxColor: const Color.fromARGB(0, 210, 16, 16),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/pizza_icon.png',
        boxColor: const Color.fromARGB(0, 210, 16, 16),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/pizza_icon.png',
        boxColor: const Color.fromARGB(0, 210, 16, 16),
      ),
    );

    return categories;
  }
}
