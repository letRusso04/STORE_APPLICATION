import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:store_application/screens/users/admin/admcategories_screen.dart';
import 'package:store_application/screens/users/admin/admccount_screen.dart';
import 'package:store_application/screens/users/admin/admcompleted_screen.dart';
import 'package:store_application/screens/users/admin/admpendingorder_screen.dart';
import 'package:store_application/screens/users/admin/admproduct_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0; // Para el BottomNavigationBar

  final List<Tab> myTabs = const [
    Tab(text: 'Cuentas'),
    Tab(text: 'Productos'),
    Tab(text: 'Categorías'),
    Tab(text: 'Pedidos pendientes'),
    Tab(text: 'Pedidos finalizados'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Inicio
        context.go('/home');
        break;
      case 1:
        // Cuenta
        context.go('/account');
        break;
      case 2:
        // Carrito
        context.go('/cart');
        break;
      case 3:
        // Admin panel (queda seleccionado aquí)
        // Nada o recarga admin
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminAccountsScreen(),
          AdminProductsScreen(),
          AdminCategoriesScreen(),
          AdminPendingOrdersScreen(),
          CompletedOrdersScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
