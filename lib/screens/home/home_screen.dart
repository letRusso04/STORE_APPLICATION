import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:store_application/models/product_model.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/product/product_screen.dart';

class Category {
  final String id;
  final String name;
  final String type; // 'carrusel' o 'grid'
  final int index;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.index,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  List<Category> _categories = [];
  List<Product> _allProducts = [];
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProducts();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _fetchCategoriesAndProducts() async {
    try {
      final catResponse = await http.get(Uri.parse('$baseUrl/categories'));
      if (catResponse.statusCode == 200) {
        final catData = jsonDecode(catResponse.body) as List;
        _categories = catData.map((json) {
          return Category(
            id: json['id'].toString(),
            name: json['name'],
            type: json['type'],
            index: json['index'] ?? 0,
          );
        }).toList();
        _categories.sort((a, b) => a.index.compareTo(b.index));
      }

      final prodResponse = await http.get(Uri.parse('$baseUrl/products'));
      if (prodResponse.statusCode == 200) {
        final prodData = jsonDecode(prodResponse.body) as List;
        _allProducts = prodData.map((json) => Product.fromJson(json)).toList();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  List<Category> get filteredCategories {
    if (_searchTerm.isEmpty) return _categories;
    return _categories.where((cat) {
      final matchName = cat.name.toLowerCase().contains(_searchTerm);
      final matchProduct = _allProducts.any(
        (p) =>
            p.category.toLowerCase() == cat.name.toLowerCase() &&
            p.title.toLowerCase().contains(_searchTerm),
      );
      return matchName || matchProduct;
    }).toList();
  }

  void _onItemTapped(int index) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/account');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        if (auth.currentUser?.role == 'admin') {
          context.go('/admin');
        }
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = user != null && user.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Tecnología')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar categorías o productos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  final productsInCategory = _allProducts
                      .where(
                        (p) =>
                            p.category.toLowerCase() == cat.name.toLowerCase(),
                      )
                      .toList();

                  if (cat.type == 'grid') {
                    return _CategoryGridSection(
                      category: cat,
                      products: productsInCategory,
                    );
                  } else if (cat.type == 'carrusel') {
                    return _CategoryCarouselSection(
                      category: cat,
                      products: productsInCategory,
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cuenta',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Administrar',
            ),
        ],
      ),
    );
  }
}

class _CategoryGridSection extends StatelessWidget {
  final Category category;
  final List<Product> products;

  const _CategoryGridSection({required this.category, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${category.name} - No hay productos disponibles',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductScreen(product: product),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: product.images.isNotEmpty
                              ? Image.network(
                                  '$baseUrl${product.images.first}',
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text('\$${product.price.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCarouselSection extends StatefulWidget {
  final Category category;
  final List<Product> products;

  const _CategoryCarouselSection({
    required this.category,
    required this.products,
  });

  @override
  State<_CategoryCarouselSection> createState() =>
      _CategoryCarouselSectionState();
}

class _CategoryCarouselSectionState extends State<_CategoryCarouselSection> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    _controller = PageController(viewportFraction: 0.85);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < widget.products.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${widget.category.name} - No hay productos disponibles',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _previousPage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreen(product: product),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    '$baseUrl${product.images.first}',
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stock: ${product.stock}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
