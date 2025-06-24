class Product {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final String category;
  final String description; // <- NUEVO

  Product({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.description,
  });
}
