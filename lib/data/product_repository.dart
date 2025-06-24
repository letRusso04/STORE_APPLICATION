import '../models/product_model.dart';

// Lista simulada para acceder desde la ruta
final List<Product> mockProducts = [
  Product(
    id: '1',
    title: 'Auriculares Bluetooth',
    imageUrl: 'https://via.placeholder.com/150',
    price: 29.99,
    category: 'Electrónica',
    description:
        'Auriculares inalámbricos con sonido envolvente, ideal para música y llamadas.',
  ),
  Product(
    id: '2',
    title: 'Laptop Gamer',
    imageUrl: 'https://via.placeholder.com/150',
    price: 899.99,
    category: 'Electrónica',
    description:
        'Auriculares inalámbricos con sonido envolvente, ideal para música y llamadas.',
  ),
  Product(
    id: '3',
    title: 'Sofá cómodo',
    imageUrl: 'https://via.placeholder.com/150',
    price: 320.00,
    category: 'Hogar',
    description:
        'Auriculares inalámbricos con sonido envolvente, ideal para música y llamadas.',
  ),
  Product(
    id: '4',
    title: 'Pantalones deportivos',
    imageUrl: 'https://via.placeholder.com/150',
    price: 45.00,
    category: 'Moda',
    description:
        'Auriculares inalámbricos con sonido envolvente, ideal para música y llamadas.',
  ),
]; // misma lista que usas en home

Product getProductById(String id) {
  return mockProducts.firstWhere((p) => p.id == id);
}
