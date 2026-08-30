import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'scan_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  // ── Executive Fintech Theme Palette ─────────────────────────────────────────
  static const Color _bg         = Color(0xFF090E17); // Deep Obsidian Canvas
  static const Color _islandBg   = Color(0xFF2563EB); // App standard primary blue
  static const Color _activeBlue = Color(0xFF090E17); // Main background color for active pill
  static const Color _inactiveIcon = Color(0xB3FFFFFF); // Semi-transparent white for contrast on blue

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onViewAllHistory: () => _switchTab(1)),
      const HistoryScreen(),
      const SizedBox.shrink(), // Placeholder for Scan (handled via modal push)
      const ProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExpenses());
  }

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  void _syncExpenses() {
    final auth = context.read<AuthProvider>();
    final expenses = context.read<ExpenseProvider>();
    if (auth.user != null) {
      expenses.fetchExpenses(auth.user!.uid);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      ).then((_) {
        _syncExpenses();
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ExpenseProvider>().clearAllExpenses();
        }
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
            child: _buildFloatingIsland(),
          ),
        ),
      ),
    );
  }

  // ── Animated Floating Pill Capsule Island ──────────────────────────────────
  Widget _buildFloatingIsland() {
    final items = [
      _NavItem(icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard_rounded, label: 'Home'),
      _NavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'History'),
      _NavItem(icon: Icons.document_scanner_outlined, selectedIcon: Icons.document_scanner_rounded, label: 'Scan'),
      _NavItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _islandBg,
        borderRadius: BorderRadius.circular(44),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          // Scan (index 2) triggers modal, so it is momentarily active or styled as button
          final isSelected = (_selectedIndex == index && index != 2);

          return GestureDetector(
            onTap: () => _onItemTapped(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: isSelected
                  ? const EdgeInsets.symmetric(horizontal: 22, vertical: 13)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isSelected ? _activeBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected ? Colors.white : _inactiveIcon,
                    size: 24,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 10),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
