import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "http://10.0.2.2:5000/api"; // Ajusta según tu entorno

// Modelo para items del pedido
class OrderItem {
  final int productId;
  final String title;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      title: json['title'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

// Modelo para información del usuario
class UserInfo {
  final String name;
  final String phone;
  final String location;
  final String estado;

  UserInfo({
    required this.name,
    required this.phone,
    required this.location,
    required this.estado,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] ?? 'Sin nombre',
      phone: json['phone'] ?? 'No disponible',
      location: json['location'] ?? 'No disponible',
      estado: json['estado'] ?? 'No disponible',
    );
  }
}

// Modelo principal Order
class Order {
  final int id;
  final UserInfo user;
  final String paymentMethod;
  final double total;
  final bool isCompleted;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.user,
    required this.paymentMethod,
    required this.total,
    required this.isCompleted,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      user: UserInfo.fromJson(json['user']),
      paymentMethod: json['method'],
      total: (json['total'] as num).toDouble(),
      isCompleted: json['is_completed'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}

class AdminPendingOrdersScreen extends StatefulWidget {
  const AdminPendingOrdersScreen({super.key});

  @override
  State<AdminPendingOrdersScreen> createState() =>
      _AdminPendingOrdersScreenState();
}

class _AdminPendingOrdersScreenState extends State<AdminPendingOrdersScreen> {
  late Future<List<Order>> _pendingOrdersFuture;

  @override
  void initState() {
    super.initState();
    _pendingOrdersFuture = fetchPendingOrders();
  }

  Future<List<Order>> fetchPendingOrders() async {
    final url = Uri.parse('$baseUrl/orders?pending=true'); // pendiente = true
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los pedidos');
    }
  }

  Future<void> _updateOrderStatus(int orderId, bool complete) async {
    final url = Uri.parse(
      '$baseUrl/orders/$orderId${complete ? '/complete' : ''}',
    );
    try {
      final response = complete
          ? await http.patch(url)
          : await http.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              complete
                  ? 'Pedido marcado como completado.'
                  : 'Pedido cancelado y eliminado.',
            ),
            backgroundColor: complete ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Actualiza la UI recargando los pedidos
        setState(() {
          _pendingOrdersFuture = fetchPendingOrders();
        });
      } else {
        throw Exception('Error en la respuesta del servidor');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el pedido: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 23, 22, 22),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Center(
                    child: Text(
                      'Detalles del Pedido #${order.id}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 201, 200, 204),
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.deepPurple.shade200,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cliente info card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.deepPurple.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Cliente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 199, 198, 201),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.user.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.user.phone,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.user.location,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estado: ${order.user.estado}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Productos card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.deepPurple.shade100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 218, 217, 222),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '\$${item.price.toStringAsFixed(2)} c/u',
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 32, thickness: 1.2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: \$${order.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 223, 222, 225),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 26),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 18,
                          ),
                          child: Text(
                            'Finalizar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Colors.green.shade200,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order.id, true);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 26),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 18,
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Colors.red.shade200,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order.id, false); // para cancelar
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos Pendientes')),
      body: FutureBuilder<List<Order>>(
        future: _pendingOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos pendientes'));
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    'Pedido #${order.id} - ${order.user.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Método: ${order.paymentMethod}\nTotal: \$${order.total.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () => _showOrderDetails(order),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
