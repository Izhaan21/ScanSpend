import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // 1. Ambient Background Elements
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF86F2E4).withValues(alpha: 0.2), // secondary-container
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDAE2FD).withValues(alpha: 0.3), // primary-fixed
              ),
            ),
          ),
          
          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  // App Identity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ScanSpend',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: const Color(0xFF131B2E),
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),

                  // High-Impact Illustration
                  Flexible(
                    flex: 10,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuCkx9oexjjiNS0VKryA6F8M0Ldr6HNtyNKjPsUDjCfX6Wj3Y1jwm8Pd_GZoQGPL8APRkb2tOFkJ1MY59ms2fz0CQ1-g6dN83k47y2Ru_ibo_4dYi9GS4Iu_xbY7qJ3kuM4PQa23_uOsgJQ3FMMUmrJ_EJzIxwgzgIGO3luUcQn7ARwuNpg3p1VVtp0-BQK_etT7gpg8zL9DMu-GMEyQQWgmUIQyO_xiMIsShijfwNZOw0t7Q1NneBnNz2ImZmzUgo-OBV84Cb0cMvCw',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 80,
                                    color: Color(0xFF006A61),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Welcome Typography
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Master Your Expenses\nwith AI',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Automate receipt scanning, categorize spending instantly, and achieve institutional-grade financial clarity.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF45464D), // on-surface-variant
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Primary Actions
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A61), // secondary
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: const Color(0xFF006A61).withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GET STARTED',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF131B2E), // primary-container
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Color(0xFFC6C6CD), width: 2), // outline-variant
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'LOG IN',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF131B2E),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
