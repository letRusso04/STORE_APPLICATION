import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:store_application/providers/auth_provider.dart';

class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({super.key});

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  late Future<List<Order>> _completedOrdersFuture;

  @override
  void initState() {
    super.initState();
    _completedOrdersFuture = fetchCompletedOrders();
  }

  Future<List<Order>> fetchCompletedOrders() async {
    final url = Uri.parse('$baseUrl/orders?pending=false');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los pedidos completados');
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pedido #${order.id}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Cliente'),
                _buildInfoRow(Icons.person, order.user.name),
                _buildInfoRow(Icons.phone, order.user.phone),
                _buildInfoRow(Icons.location_on, order.user.location),
                _buildInfoRow(Icons.map, 'Estado: ${order.user.estado}'),
                const SizedBox(height: 24),
                _buildSectionTitle('Productos'),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'x${item.quantity}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 32, color: Colors.white24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.lightBlueAccent,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos Completados')),
      body: FutureBuilder<List<Order>>(
        future: _completedOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos completados'));
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text('Pedido #${order.id} - ${order.user.name}'),
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
