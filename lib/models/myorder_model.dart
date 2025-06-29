class MyOrderItem {
  final int id;
  final String method;
  final double total;
  final bool isCompleted;
  final DateTime createdAt;
  final List<OrderItem> items; // <-- Aquí la lista de items

  MyOrderItem({
    required this.id,
    required this.method,
    required this.total,
    required this.isCompleted,
    required this.createdAt,
    required this.items,
  });

  factory MyOrderItem.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['items'] as List<dynamic>? ?? [];
    List<OrderItem> itemsList = itemsJson
        .map((i) => OrderItem.fromJson(i))
        .toList();

    return MyOrderItem(
      id: json['id'],
      method: json['method'],
      total: (json['total'] as num).toDouble(),
      isCompleted: json['is_completed'],
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList,
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
      subtotal: (json['price'] as num).toDouble() * json['quantity'],
    );
  }
}
