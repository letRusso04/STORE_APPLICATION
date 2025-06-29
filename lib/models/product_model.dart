class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final int stock;
  final String category;

  final String? imageUrl1;
  final String? imageUrl2;
  final String? imageUrl3;
  final String? imageUrl4;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.imageUrl1,
    this.imageUrl2,
    this.imageUrl3,
    this.imageUrl4,
  });

  // Devuelve una lista limpia de las imágenes existentes
  List<String> get images {
    return [
      imageUrl1,
      imageUrl2,
      imageUrl3,
      imageUrl4,
    ].whereType<String>().where((url) => url.isNotEmpty).toList();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'] ?? '',
      imageUrl1: json['image_url1'],
      imageUrl2: json['image_url2'],
      imageUrl3: json['image_url3'],
      imageUrl4: json['image_url4'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'image_url1': imageUrl1,
      'image_url2': imageUrl2,
      'image_url3': imageUrl3,
      'image_url4': imageUrl4,
    };
  }
}
