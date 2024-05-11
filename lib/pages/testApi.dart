import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
}

class Product {
  final String name;
  final int id;
  final int categoryId;
  final String? imagePath; // Added imagePath field

  Product(
      {required this.name,
      required this.id,
      required this.categoryId,
      this.imagePath});
}

class MyDataFetcher extends StatefulWidget {
  @override
  _MyDataFetcherState createState() => _MyDataFetcherState();
}

class _MyDataFetcherState extends State<MyDataFetcher>
    with TickerProviderStateMixin {
  List<Category> categories = [];
  late TabController _tabController;
  List<Product> allProducts = [];
  Map<int, ScrollController> _categoryScrollControllers = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryScrollControllers.values
        .forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1'));

    if (response.statusCode == 200) {
      List<dynamic> categoryData = json.decode(response.body);
      List<Product> mergedProducts = [];
      for (var category in categoryData) {
        List<dynamic> productData = category['products'];
        int categoryId = category['id'];
        List<Product> products = productData.map((product) {
          var photo = product['photo'];
          String? imagePath = photo != null
              ? 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}'
              : null;
          return Product(
            name: product['name'],
            id: product['id'],
            categoryId: categoryId,
            imagePath: imagePath,
          );
        }).toList();
        mergedProducts.addAll(products);
        categories.add(Category(id: categoryId, name: category['name']));
        _categoryScrollControllers[categoryId] = ScrollController();
      }
      setState(() {
        allProducts = mergedProducts;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return allProducts.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: Text('Categories'),
            ),
            body: Column(
              children: [
                // Row of buttons with category names
                Container(
                  color: Colors.blue,
                  height: 50, // Set the height of the row
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scroll
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      Category category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: ElevatedButton(
                          onPressed: () {
                            print('Category ID: ${category.id}');
                            _scrollToCategory(category.id);
                          },
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                                    (states) {
                              return Colors.black;
                            }),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.transparent),
                            elevation: MaterialStateProperty.all<double>(
                                0), // No elevation
                          ),
                          child: Text(category.name),
                        ),
                      );
                    },
                  ),
                ),
                // List of products for each category
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: categories.map((category) {
                        List<Product> productsInCategory = allProducts
                            .where(
                                (product) => product.categoryId == category.id)
                            .toList();
                        return Column(
                          key: ValueKey<int>(category.id),
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListView.builder(
                              controller:
                                  _categoryScrollControllers[category.id],
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: productsInCategory.length,
                              itemBuilder: (context, productIndex) {
                                Product product =
                                    productsInCategory[productIndex];
                                return ListTile(
                                  leading: product.imagePath != null
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(product.imagePath!),
                                        )
                                      : Icon(Icons.photo),
                                  title: Text(product.name),
                                  subtitle: Text('id: ${product.id}'),
                                );
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  void _scrollToCategory(int categoryId) {
    ScrollController? controller = _categoryScrollControllers[categoryId];
    print(controller);
    if (controller != null && controller.hasClients) {
      Scrollable.ensureVisible(
        controller.position.context.storageContext,
        alignment: 0.0,
        duration: Duration(milliseconds: 300),
      );
    }
  }
}

void main() {
  runApp(MaterialApp(home: MyDataFetcher()));
}
