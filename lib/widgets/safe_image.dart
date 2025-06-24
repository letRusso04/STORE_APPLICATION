import 'package:flutter/material.dart';

class SafeImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }
}
