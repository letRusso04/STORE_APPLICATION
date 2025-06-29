import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:store_application/models/myorder_model.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/users/admin/admcompleted_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _selectedFilter = 'all';
  late Future<List<MyOrderItem>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId != null) {
      _ordersFuture = fetchOrders(userId, _selectedFilter);
    }
  }

  Future<List<MyOrderItem>> fetchOrders(int userId, String filter) async {
    String url = '$baseUrl/my-orders?user_id=$userId';
    if (filter == 'completed') {
      url += '&status=completed';
    } else if (filter == 'pending') {
      url += '&status=pending';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => MyOrderItem.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar pedidos');
    }
  }

  void _showOrderDetails(MyOrderItem order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            children: [
              Center(
                child: Text(
                  'Detalle Pedido #${order.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ...order.items.map(
                (item) => ListTile(
                  title: Text(item.title),
                  subtitle: Text('Cantidad: ${item.quantity}'),
                  trailing: Text('\$${item.subtotal.toStringAsFixed(2)}'),
                ),
              ),

              const Divider(),
              ListTile(
                title: const Text('Total'),
                trailing: Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar Pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await _cancelOrder(order.id);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pedido cancelado')),
                      );
                      _loadOrders();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al cancelar pedido'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _cancelOrder(int orderId) async {
    final url = Uri.parse('$baseUrl/orders/$orderId');
    final response = await http.delete(url);
    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
                _loadOrders();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completados'),
              ),
              const PopupMenuItem(value: 'pending', child: Text('Pendientes')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: FutureBuilder<List<MyOrderItem>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    order.isCompleted ? Icons.check_circle : Icons.timelapse,
                    color: order.isCompleted ? Colors.green : Colors.orange,
                  ),
                  title: Text('Pedido #${order.id}'),
                  subtitle: Text(
                    'Método: ${order.method}\nTotal: \$${order.total.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _showOrderDetails(order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
