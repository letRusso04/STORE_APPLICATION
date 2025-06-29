import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:store_application/providers/auth_provider.dart';

class ProductDetailAdmScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailAdmScreen({super.key, required this.product});

  @override
  State<ProductDetailAdmScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailAdmScreen> {
  late int stock;
  int currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    stock = widget.product['stock'] ?? 0;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _increaseStock() async {
    setState(() => stock++);
    await _updateStockOnServer();
  }

  void _decreaseStock() async {
    if (stock > 0) {
      setState(() => stock--);
      await _updateStockOnServer();
    }
  }

  Future<void> _updateStockOnServer() async {
    final productId = widget.product['id'];
    final url = Uri.parse('$baseUrl/products/$productId/stock');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stock': stock}),
      );

      if (response.statusCode == 200) {
        // Opcional: parsear respuesta si quieres
      } else {
        // Error: revertir cambio local si quieres
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar stock: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  void _onPageChanged(int index) {
    setState(() => currentImageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final imageUrls =
        [
              product['image_url1'],
              product['image_url2'],
              product['image_url3'],
              product['image_url4'],
            ]
            .where((url) => url != null && url.toString().isNotEmpty)
            .map((url) => '$baseUrl$url')
            .toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Producto'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel + flechas + indicadores
            if (imageUrls.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 260,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Flecha izquierda
                  if (imageUrls.length > 1)
                    Positioned(
                      left: 4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                          size: 26,
                        ),
                        onPressed: () {
                          int prevIndex =
                              (currentImageIndex - 1 + imageUrls.length) %
                              imageUrls.length;
                          _pageController.animateToPage(
                            prevIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),

                  // Flecha derecha
                  if (imageUrls.length > 1)
                    Positioned(
                      right: 4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 26,
                        ),
                        onPressed: () {
                          int nextIndex =
                              (currentImageIndex + 1) % imageUrls.length;
                          _pageController.animateToPage(
                            nextIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),

                  // Indicadores abajo
                  Positioned(
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentImageIndex == index ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentImageIndex == index
                                ? Colors.deepPurple
                                : Colors.deepPurple.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 120,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        product['name'] ?? '-',
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 237, 236, 240),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Categoría: ${product['category'] ?? '-'}',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: const Color.fromARGB(255, 231, 228, 228),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Precio: \$${product['price'] ?? '-'}',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: const Color.fromARGB(255, 240, 239, 241),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Disponible',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 244, 243, 245),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.all(12),
                            elevation: 5,
                            shadowColor: Colors.redAccent.shade100,
                          ),
                          onPressed: _decreaseStock,
                          child: const Icon(Icons.remove, size: 28),
                        ),
                        const SizedBox(width: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Text(
                            '$stock',
                            key: ValueKey<int>(stock),
                            style: theme.textTheme.headlineMedium!.copyWith(
                              color: const Color.fromARGB(255, 250, 249, 252),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: Colors.green.shade400,
                            padding: const EdgeInsets.all(12),
                            elevation: 5,
                            shadowColor: Colors.greenAccent.shade100,
                          ),
                          onPressed: _increaseStock,
                          child: const Icon(Icons.add, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
