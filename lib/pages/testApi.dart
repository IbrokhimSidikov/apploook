import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Category {
  final String name;
  final List<Product> products;

  Category({required this.name, required this.products});
}

class Product {
  final String name;
  final int id;
  final String? imageUrl; // Added imageUrl property

  Product({required this.name, required this.id, this.imageUrl});
}

class MyDataFetcher extends StatefulWidget {
  @override
  _MyDataFetcherState createState() => _MyDataFetcherState();
}

class _MyDataFetcherState extends State<MyDataFetcher> {
  List<Category> categories = [];
  late ScrollController? _scrollController;
  Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    fetchData();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1'));

    if (response.statusCode == 200) {
      List<dynamic> categoryData = json.decode(response.body);
      List<Category> mergedCategories = [];
      for (var category in categoryData) {
        List<dynamic> productData = category['products'];
        List<Product> products = productData.map((product) {
          return Product(
              name: product['name'],
              id: product['id'],
              imageUrl: product['photo'] != null &&
                      product['photo']['path'] != null &&
                      product['photo']['name'] != null &&
                      product['photo']['format'] != null
                  ? 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${product['photo']['path']}/${product['photo']['name']}.${product['photo']['format']}'
                  : null);
        }).toList();
        mergedCategories
            .add(Category(name: category['name'], products: products));
      }
      setState(() {
        categories = mergedCategories;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void _scrollToCategory(Category category) {
    int index = categories.indexOf(category);
    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += (2 + categories[i].products.length) *
          56; // 2 for ListTile and SizedBox, 56 is the height of ListTile
    }
    _scrollController?.animateTo(offset,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  void _onScroll() {
    double offset = _scrollController!.offset;
    int currentIndex = 0;
    for (int i = 0; i < categories.length; i++) {
      offset -= (2 + categories[i].products.length) *
          56; // 2 for ListTile and SizedBox, 56 is the height of ListTile
      if (offset <= 0) {
        currentIndex = i;
        break;
      }
    }
    setState(() {
      selectedCategory = categories[currentIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return categories.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: Text('Categories'),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = category;
                          });
                          _scrollToCategory(category);
                        },
                        child: Text(category.name),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors
                                    .green; // Change to your desired color
                              }
                              return selectedCategory == category
                                  ? Colors.blue // Change to your desired color
                                  : Colors.grey; // Change to your desired color
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: categories.length,
                    itemBuilder: (context, categoryIndex) {
                      Category category = categories[categoryIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ListTile(
                            title: Text(category.name),
                            // Add whatever styling you want for categories
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemCount: category.products.length,
                            itemBuilder: (context, productIndex) {
                              Product product = category.products[productIndex];
                              return Column(
                                children: [
                                  product.imageUrl != null
                                      ? Container(
                                          height: 150.0,
                                          width: 150.0,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  product.imageUrl!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                  ListTile(
                                    title: Text(product.name),
                                    subtitle: Text('id: ${product.id}'),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(
                              height:
                                  10), // Add some spacing between categories
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}

void main() {
  runApp(MaterialApp(home: MyDataFetcher()));
}
