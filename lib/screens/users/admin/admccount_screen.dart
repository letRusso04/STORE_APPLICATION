import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:store_application/models/user.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'package:store_application/screens/users/account_screen.dart';
import 'package:store_application/screens/users/widgets/edit_user_screen.dart'
    hide User;

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/users');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allUsers = data.map((u) => User.fromJson(u)).toList();
        _filteredUsers = List.from(_allUsers);
      } else {
        _error = 'Error al cargar usuarios: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar usuario ${user.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Lógica para eliminar usuario en backend:
    try {
      final uri = Uri.parse('$baseUrl/users/${user.id}');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        setState(() {
          _allUsers.removeWhere((u) => u.id == user.id);
          _filteredUsers.removeWhere((u) => u.id == user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario ${user.name} eliminado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar usuario: $e')));
    }
  }

  void _editUser(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditedUserScreen(
          user: user,
          onUserUpdated: () {
            // Refrescar lista luego de la actualización:
            _fetchUsers();
          },
        ),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.grey.shade300,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: user.role == 'admin'
              ? Colors.deepPurple
              : Colors.blueGrey,
          child: Text(
            user.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Text(
              user.role == 'admin' ? 'Administrador' : 'Usuario',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: user.role == 'admin'
                    ? Colors.deepPurple
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          alignment: WrapAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              tooltip: 'Editar usuario',
              onPressed: () => _editUser(user),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Eliminar usuario',
              onPressed: () => _deleteUser(user),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Cuentas'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuario por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  )
                : _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron usuarios',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
