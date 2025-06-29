import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:store_application/screens/users/widgets/add_product_screen.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/users/widgets/admdetails_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

String buildFullImageUrl(String? relativePath) {
  if (relativePath == null || relativePath.isEmpty) return '';
  if (relativePath.startsWith('http')) return relativePath;
  return '$baseUrl$relativePath';
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> allProducts = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        setState(() {
          allProducts = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      // error
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _categories = data
              .map<String>((cat) => cat['name'] as String)
              .toList();
        });
      }
    } catch (e) {
      // error
    }
  }

  void _showProductDetail(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(product['image'] ?? '', height: 150),
            const SizedBox(height: 8),
            Text('Categoría: ${product['category']}'),
            Text('Precio: \$${product['price']}'),
            Text('Stock: ${product['stock']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    final formKey = GlobalKey<FormState>();

    String name = product['name'];
    String category = product['category'];
    String price = product['price'].toString();
    String stock = product['stock'].toString();
    String description = product['description'] ?? '';

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Producto',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => name = v,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) => category = v!,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Seleccione una categoría'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  TextFormField(
                    initialValue: price,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => price = v,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Precio inválido'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Stock
                  TextFormField(
                    initialValue: stock,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => stock = v,
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Stock inválido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final res = await http.put(
                              Uri.parse('$baseUrl/products/${product['id']}'),
                              headers: {
                                'Content-Type':
                                    'application/x-www-form-urlencoded',
                              },
                              body: {
                                'name': name,
                                'category': category,
                                'price': price,
                                'stock': stock,
                                'description': description,
                              },
                            );
                            if (res.statusCode == 200) {
                              Navigator.pop(context);
                              _fetchProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Producto actualizado correctamente',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al actualizar producto: ${res.statusCode}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteProduct(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('¿Deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await http.delete(Uri.parse('$baseUrl/products/$id'));
              _fetchProducts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = allProducts.where((product) {
      final query = _searchQuery.toLowerCase();
      return product['name'].toLowerCase().contains(query) ||
          product['category'].toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Productos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Buscar producto',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Nombre o categoría',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final imageUrl = buildFullImageUrl(product['image_url1']);

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                  title: Text(product['name'] ?? ''),
                  subtitle: Text(
                    'Categoría: ${product['category']}\nPrecio: \$${product['price']} | Stock: ${product['stock']}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailAdmScreen(product: product),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editProduct(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) => _fetchProducts());
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
