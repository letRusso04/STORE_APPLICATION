import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_application/widgets/product_cart.dart';
import '../../providers/favorites_provider.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home'); // Navega directo a Home
          },
        ),
      ),
      body: favorites.isEmpty
          ? const Center(child: Text('No tienes productos favoritos.'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    context.push('/product/${product.id}');
                  },
                );
              },
            ),
    );
  }
}
