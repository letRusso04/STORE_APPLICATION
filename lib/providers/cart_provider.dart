import 'package:flutter/material.dart';
import 'package:store_application/models/cart_model.dart';
import 'package:store_application/models/product_model.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  void addToCart(Product product, int quantity) {
    if (_items.containsKey(product.id)) {
      // Si ya existe, suma la cantidad (pero sin pasarse del stock)
      final existing = _items[product.id]!;
      final newQuantity = existing.quantity + quantity;
      existing.quantity = newQuantity <= product.stock
          ? newQuantity
          : product.stock;
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: quantity),
      );
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
