import 'dart:convert';

class MenuCategory {
  final int id;
  final String name;
  final List<MenuItem> items;
  bool isSelected;

  MenuCategory({
    required this.id,
    required this.name,
    required this.items,
    this.isSelected = false,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    List<MenuItem> items = [];
    if (json['products'] != null) {
      items = List<MenuItem>.from(
        json['products']
            .map((item) => MenuItem.fromJson(item, json['id'], json['name'])),
      );
    }

    return MenuCategory(
      id: json['id'],
      name: json['name'].toString().split('_')[0],
      items: items,
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final int categoryId;
  final String categoryTitle;
  final String? imagePath;
  final double price;
  final dynamic description;

  MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryTitle,
    this.imagePath,
    required this.price,
    required this.description,
  });

  factory MenuItem.fromJson(
      Map<String, dynamic> json, int categoryId, String categoryTitle) {
    dynamic description = json['description'];
    if (description is String) {
      try {
        description = jsonDecode(description);
      } catch (e) {
        print('Error parsing description: $e');
      }
    }

    String? imagePath;
    if (json['photo'] != null) {
      imagePath =
          'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${json['photo']['path']}/${json['photo']['name']}.${json['photo']['format']}';
    }

    return MenuItem(
      id: json['id'],
      name: json['name'],
      categoryId: categoryId,
      categoryTitle: categoryTitle.split('_')[0],
      imagePath: imagePath,
      price: json['priceList'] != null
          ? json['priceList']['price'].toDouble()
          : 0.0,
      description: description,
    );
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (description != null && description is Map<String, dynamic>) {
      return description[languageCode];
    } else if (description != null && description is String) {
      try {
        Map<String, dynamic> descriptionMap = json.decode(description);
        return descriptionMap[languageCode];
      } catch (e) {
        print('Error parsing description: $e');
      }
    }
    return null;
  }
}

class MenuAdapter {
  static List<MenuCategory> convertToCategories(List<dynamic> apiResponse) {
    return apiResponse
        .where((category) =>
            !category['name'].toString().toLowerCase().contains('ava'))
        .map((category) => MenuCategory.fromJson(category))
        .toList();
  }
}
