import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/users/widgets/product_bycate_screen.dart';

class Category {
  final int id;
  String name;
  String type; // 'carrusel' o 'grid'
  int index; // Índice para orden

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.index,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    index: json['index'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'index': index,
  };
}

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(_categories);
    _searchController.addListener(_filterCategories);
    _fetchCategoriesFromApi();
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _fetchCategoriesFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _categories = data.map((json) => Category.fromJson(json)).toList();
          _filteredCategories = List.from(_categories);
        });
      } else {
        // Manejar error
        debugPrint('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error de conexión: $e');
    }
  }

  Future<void> _addCategory() async {
    final formKey = GlobalKey<FormState>();
    String newName = '';
    String newType = 'carrusel';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Categoría'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => newName = value.trim(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  value: newType,
                  items: const [
                    DropdownMenuItem(
                      value: 'carrusel',
                      child: Text('Carrusel'),
                    ),
                    DropdownMenuItem(value: 'grid', child: Text('Grid')),
                  ],
                  onChanged: (value) {
                    if (value != null) newType = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/categories'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': newName, 'type': newType}),
        );

        if (response.statusCode == 201) {
          final json = jsonDecode(response.body);
          final newCategory = Category.fromJson(json);
          setState(() {
            _categories.add(newCategory);
            _filteredCategories = List.from(_categories);
            _searchController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Categoría "$newName" agregada exitosamente'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al agregar categoría')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  Future<void> _editCategory(Category category) async {
    final formKey = GlobalKey<FormState>();
    // Ya no se edita el nombre
    String newType = category.type;
    int newIndex = category.index;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quitamos el campo de nombre para editar
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  value: newType,
                  items: const [
                    DropdownMenuItem(
                      value: 'carrusel',
                      child: Text('Carrusel'),
                    ),
                    DropdownMenuItem(value: 'grid', child: Text('Grid')),
                  ],
                  onChanged: (v) {
                    if (v != null) newType = v;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: newIndex.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Índice',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = int.tryParse(v ?? '');
                    if (val == null || val < 1) return 'Índice inválido';
                    return null;
                  },
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) newIndex = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/categories/${category.id}/swap-index'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            // No enviamos nombre porque no se puede editar
            'type': newType,
            'new_index': newIndex,
          }),
        );

        if (response.statusCode == 200) {
          await _fetchCategoriesFromApi();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Categoría actualizada')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar categoría')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  Future<void> _deleteCategory(int id, String categoryName) async {
    try {
      // Consultar si la categoría tiene productos
      final hasProductsResponse = await http.get(
        Uri.parse('$baseUrl/categories/$id/has-products'),
      );

      if (hasProductsResponse.statusCode == 200) {
        final data = jsonDecode(hasProductsResponse.body);
        final hasProducts = data['has_products'] as bool;

        if (hasProducts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se puede eliminar la categoría "$categoryName" porque tiene productos asociados.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return; // Salir sin eliminar
        }
      } else {
        // Si fallo la consulta, igual evitar borrar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al validar productos asociados')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      return;
    }

    // Confirmar eliminación como antes
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la categoría "$categoryName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/categories/$id'),
        );
        if (response.statusCode == 200) {
          setState(() {
            _categories.removeWhere((cat) => cat.id == id);
            _filteredCategories = List.from(_categories);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar categoría')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Categorías'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Categorías',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCategories.isEmpty
                  ? const Center(child: Text('No se encontraron categorías'))
                  : ListView.separated(
                      itemCount: _filteredCategories.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final cat = _filteredCategories[index];
                        return ListTile(
                          title: Text(cat.name),
                          subtitle: Text(
                            'Tipo: ${cat.type} - Índice: ${cat.index}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.green,
                                ),
                                tooltip: 'Ver',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.list),
                                            title: const Text(
                                              'Mostrar productos',
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProductsByCategoryScreen(
                                                        category: cat,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.cancel),
                                            title: const Text('Cancelar'),
                                            onTap: () => Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Editar',
                                onPressed: () => _editCategory(cat),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar',
                                onPressed: () =>
                                    _deleteCategory(cat.id, cat.name),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        tooltip: 'Agregar Categoría',
      ),
    );
  }
}
