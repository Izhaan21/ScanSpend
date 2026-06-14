import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/ocr_service.dart';
import 'services/ai_service.dart';
import 'services/firestore_service.dart';

import 'screens/auth/auth_wrapper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e — running without Firebase');
  }
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
            FirestoreService(),
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
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/welcome': (context) => const AuthWrapper(),
          },
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onViewAllHistory: () => _switchTab(1)),
      const HistoryScreen(),
      const SizedBox.shrink(),
      const ProfileScreen(),
    ];

    // Fetch expenses once auth is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExpenses());
  }

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  void _syncExpenses() {
    final auth = context.read<AuthProvider>();
    final expenses = context.read<ExpenseProvider>();
    if (auth.user != null && expenses.expenses.isEmpty) {
      expenses.fetchExpenses(auth.user!.uid);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      ).then((_) {
        // Refresh after returning from scan
        _syncExpenses();
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes to clear expenses on logout
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      // Auth wrapper will redirect to welcome, but clear data proactively
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExpenseProvider>().clearAllExpenses();
      });
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: const Color(0xFF006A61).withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF006A61)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF006A61)),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner, color: Color(0xFF006A61)),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF006A61)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
