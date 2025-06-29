import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_application/providers/auth_provider.dart';
import 'account_screen.dart';
import '../auth/login_screen.dart';

class AccountWrapperScreen extends StatelessWidget {
  const AccountWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return isLoggedIn ? const AccountScreen() : const LoginScreen();
  }
}
