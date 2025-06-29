import 'package:go_router/go_router.dart';
import 'package:store_application/models/product_model.dart';
import 'package:store_application/screens/cart/cart_screen.dart';
import 'package:store_application/screens/favorites/favorites_screen.dart';
import 'package:store_application/screens/users/AccountWrapperScreen.dart';
import 'package:store_application/screens/users/admin_screen.dart';
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
      /*  GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          final product = getProductById(productId);
          return ProductScreen(product: product, allProducts: allProducts);
        },
      ),*/
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountWrapperScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
    ],
  );
}
