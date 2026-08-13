import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import 'welcome_screen.dart';
import '../main_navigation_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isNowAuthenticated = authProvider.isAuthenticated;

        // Just logged in → fetch expenses
        if (isNowAuthenticated && !_wasAuthenticated) {
          _wasAuthenticated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (authProvider.user != null) {
              context.read<ExpenseProvider>().fetchExpenses(authProvider.user!.uid);
            }
          });
        }

        // Just logged out → clear expenses
        if (!isNowAuthenticated && _wasAuthenticated) {
          _wasAuthenticated = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ExpenseProvider>().clearAllExpenses();
            }
          });
        }

        if (isNowAuthenticated) {
          return const MainNavigationScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
