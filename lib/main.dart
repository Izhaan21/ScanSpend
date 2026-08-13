import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/ocr_service.dart';
import 'services/ai_service.dart';
import 'services/api_service.dart';

import 'screens/auth/auth_wrapper.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Make the system status bar transparent so the background flows under it
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons for dark background
    ),
  );

  runApp(const ScanSpendApp());
}

class ScanSpendApp extends StatelessWidget {
  const ScanSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(
            OCRService(),
            AIService(),
            ApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'ScanSpend',
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

