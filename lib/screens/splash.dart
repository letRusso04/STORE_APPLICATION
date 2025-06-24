import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa addPostFrameCallback para no llamar navegación durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        context.go('/home'); // navega usando go_router
      });
    });

    return const Scaffold(body: Center(child: Text('Amazon Clone - Splash')));
  }
}
