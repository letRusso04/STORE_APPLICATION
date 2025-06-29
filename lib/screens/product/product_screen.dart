import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_application/models/product_model.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/providers/cart_provider.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int quantity = 1;
  final PageController _pageController = PageController();

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addToCart(widget.product, quantity);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: const Color.fromARGB(255, 238, 238, 239),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Color.fromARGB(255, 0, 0, 0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${widget.product.title} x$quantity agregado(s) al carrito',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carrusel de imágenes
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                final imageUrl = product.images[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      '$baseUrl${imageUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 60),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              product.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // Descripción grande y llamativa, abajo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              product.description,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 235, 234, 236),
              ),
            ),
          ),
          const Spacer(),
          // Precio y stock un poco más arriba
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Text(
                  'Stock: ${product.stock}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Parte inferior con cantidad y botón, subida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Cantidad:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: quantity < product.stock
                      ? () => setState(() => quantity++)
                      : null,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: product.stock > 0 ? _addToCart : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Añadir al carrito'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
