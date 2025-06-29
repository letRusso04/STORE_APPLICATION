import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '$baseUrl${item.product.imageUrl1}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 60),
                          ),
                        ),
                        title: Text(item.product.title),
                        subtitle: Text(
                          'Precio unitario: \$${item.product.price.toStringAsFixed(2)}\nCantidad: ${item.quantity}',
                        ),
                        trailing: SizedBox(
                          width: 180, // un poco más ancho para evitar overflow
                          child: Wrap(
                            spacing: 2,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: item.quantity > 1
                                    ? () {
                                        cartProvider.addToCart(
                                          item.product,
                                          -1,
                                        );
                                      }
                                    : null,
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: item.quantity < item.product.stock
                                    ? () {
                                        cartProvider.addToCart(item.product, 1);
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  cartProvider.removeFromCart(item.product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Total price
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total a pagar',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Botón pagar
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Selecciona un método de pago',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: const Icon(Icons.money),
                                  title: const Text('Efectivo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showPaymentConfirmation(
                                      context,
                                      'Efectivo',
                                      cartProvider,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.account_balance),
                                  title: const Text('Transferencia'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showPaymentConfirmation(
                                      context,
                                      'Transferencia',
                                      cartProvider,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.phone_iphone),
                                  title: const Text('Pago Móvil'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showPaymentConfirmation(
                                      context,
                                      'Pagomovil',
                                      cartProvider,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tu información de contacto será enviada al administrador, quien se comunicará contigo a la brevedad.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      255,
                                      234,
                                      233,
                                      233,
                                    ),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.payment, size: 28),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      child: Text('Pagar', style: TextStyle(fontSize: 18)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 8,
                      shadowColor: Colors.orangeAccent.shade200,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

void _showPaymentConfirmation(
  BuildContext context,
  String method,
  CartProvider cartProvider,
) async {
  final authProvider = context.read<AuthProvider>();

  if (!authProvider.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesión para realizar una compra.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    context.go('/login');
    return;
  }

  // Esperamos el resultado del diálogo para continuar
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar compra'),
      content: Text(
        '¿Deseas confirmar tu compra usando $method?\n'
        'Tu información será enviada al administrador para contacto.',
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar'),
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final orderData = {
    'user_id': authProvider.currentUser!.id,
    'name': authProvider.currentUser!.name,
    'payment_method': method,
    'total': cartProvider.totalPrice,
    'items': cartProvider.items.values
        .map(
          (item) => {
            'product_id': item.product.id,
            'title': item.product.title,
            'quantity': item.quantity,
            'unit_price': item.product.price,
          },
        )
        .toList(),
    'is_completed': false,
  };

  final url = Uri.parse('$baseUrl/orders');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(orderData),
  );

  if (res.statusCode == 201) {
    cartProvider.clearCart();
    context.go('/home'); // redirige después de cerrar el diálogo
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al enviar el pedido: ${res.body}'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
