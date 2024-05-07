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
        name: 'Cappuccino',
        imagePath: 'images/nestle_05l.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Cappuccino',
        imagePath: 'images/nestle_1l.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Cappuccino',
        imagePath: 'images/nestle_15l.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Cappuccino',
        imagePath: 'images/IMG_3204.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Black tea',
        imagePath: 'images/IMG_3233.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Green tea',
        imagePath: 'images/IMG_3235.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Lemon tea',
        imagePath: 'images/IMG_3220.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Coffee 3 in 1',
        imagePath: 'images/3in1.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Americano',
        imagePath: 'images/americano.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Americano Large',
        imagePath: 'images/americano_large.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Cappuccino Large',
        imagePath: 'images/cappuccino_large.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    // categories.add(
    //   CategoryModel(
    //     name: 'Drinks',
    //     imagePath: 'images/ice_cappuccino.png',
    //     boxColor: const Color.fromARGB(255, 145, 140, 140),
    //   ),
    // );
    categories.add(
      CategoryModel(
        name: 'Ice Frappucino',
        imagePath: 'images/ice_frappuccino.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/ice_latte.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/latte.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );
    categories.add(
      CategoryModel(
        name: 'Drinks',
        imagePath: 'images/latte_large.png',
        boxColor: const Color.fromARGB(255, 145, 140, 140),
      ),
    );

    return categories;
  }
}
