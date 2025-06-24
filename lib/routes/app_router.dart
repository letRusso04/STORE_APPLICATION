import 'package:go_router/go_router.dart';
import 'package:store_application/data/product_repository.dart';
import 'package:store_application/screens/cart/cart_screen.dart';
import 'package:store_application/screens/favorites/favorites_screen.dart';
import '../screens/splash.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/product/product_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          final product = getProductById(
            productId,
          ); // Te muestro cómo en el paso siguiente
          return ProductScreen(product: product);
        },
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  );
}
