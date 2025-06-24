import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';

class SubCategory {
  final String id;
  final String name;
  final String imageUrl;

  SubCategory({required this.id, required this.name, required this.imageUrl});
}

class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;

  Category({required this.id, required this.name, required this.subCategories});
}

final List<Map<String, String>> carouselItems = [
  {
    'image':
        'https://images.unsplash.com/photo-1606813909355-cbedf7a90a24?w=1080',
    'title': 'Nuevas Laptops 2025',
    'route': '/category/laptops',
  },
  {
    'image':
        'https://images.unsplash.com/photo-1503602642458-232111445657?w=1080',
    'title': 'Tecnología para el hogar',
    'route': '/category/smarthome',
  },
  {
    'image':
        'https://images.unsplash.com/photo-1587202372775-34f4911088aa?w=1080',
    'title': 'Gadgets portátiles',
    'route': '/category/gadgets',
  },
];

final List<Category> techCategories = [
  Category(
    id: 'computadoras',
    name: 'Computadoras',
    subCategories: [
      SubCategory(
        id: 'pc',
        name: 'PC Escritorio',
        imageUrl:
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600',
      ),
      SubCategory(
        id: 'portatiles',
        name: 'Portátiles',
        imageUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600',
      ),
      SubCategory(
        id: 'monitores',
        name: 'Monitores',
        imageUrl:
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
      ),
      SubCategory(
        id: 'componentes',
        name: 'Componentes',
        imageUrl:
            'https://images.unsplash.com/photo-1587202372775-34f4911088aa?w=600',
      ),
    ],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  String _searchTerm = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Category> get filteredCategories {
    if (_searchTerm.isEmpty) return techCategories;
    return techCategories
        .map((category) {
          final filteredSubs = category.subCategories
              .where(
                (sub) =>
                    sub.name.toLowerCase().contains(_searchTerm) ||
                    category.name.toLowerCase().contains(_searchTerm),
              )
              .toList();
          if (filteredSubs.isEmpty) return null;
          return Category(
            id: category.id,
            name: category.name,
            subCategories: filteredSubs,
          );
        })
        .whereType<Category>()
        .toList();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/account');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/options');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tecnología'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar subcategorías...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: carouselItems.length,
                itemBuilder: (_, index) {
                  final item = carouselItems[index];
                  return GestureDetector(
                    onTap: () => context.go(item['route']!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item['image']!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 60),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
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
            const SizedBox(height: 8),
            SmoothPageIndicator(
              controller: _pageController,
              count: carouselItems.length,
              effect: const ExpandingDotsEffect(
                activeDotColor: Colors.deepPurple,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: filteredCategories
                      .map((cat) => CategorySection(category: cat))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
        ],
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final Category category;

  const CategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            itemCount: category.subCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (_, index) {
              final sub = category.subCategories[index];
              return GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionado: ${sub.name}')),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          sub.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sub.name,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
