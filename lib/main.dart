import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_application/providers/cart_provider.dart';
import 'package:store_application/providers/favorites_provider.dart';
import 'package:store_application/routes/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        //ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.router,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.grey[900],
            selectedItemColor: Colors.orangeAccent,
            unselectedItemColor: Colors.grey[500],
            showUnselectedLabels: true,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
