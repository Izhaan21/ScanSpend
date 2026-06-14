import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().login(email, password);
      // MainNavigationScreen is handled by AuthWrapper on state change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await context.read<AuthProvider>().loginWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Decorative Background Element
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBHs08iZGvbSazS81ZXGBieeXMVjWgnTXlYTMwx8HUpvBkOVEbTjYsf-dmodaG0L3-b9n6yfhx3p3TmBBUTpPFagZ825cfoKZ-6YdfYwEWNN7OIl1-aX9EysPzDoCPudlPieS8aGOewQYQ-zjltviyyHwjwElJPA0VoQ3nxDS6o5_MVIesgszDZTQ-zRO9wR76uLRvlbskKynbwYBkifqh0p04szrhTpjU9T5IqewDazHCmGy1OoC96kCJbsQHL3Yl-dUOc5wksVCd7',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.5,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                    const Color(0xFFE0E3E5).withValues(alpha: 0.9), // surface-variant
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48.0), // -48 for vertical padding
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC6C6CD).withValues(alpha: 0.3)), // outline-variant
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand & Headline
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEEF0), // surface-container
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC6C6CD).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF006A61), size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to manage your expenses.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF45464D), // on-surface-variant
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Area
                      _buildTextField(
                        theme: theme,
                        controller: _emailController,
                        label: 'Email',
                        hint: 'name@company.com',
                        icon: Icons.mail_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        theme: theme,
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        trailingAction: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Forgot Password?',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF006A61), // secondary
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Primary Login Action
                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006A61), // secondary
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFC6C6CD))), // outline-variant
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF76777D), // outline
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFC6C6CD))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Login
                      OutlinedButton.icon(
                        onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                        icon: Image.network(
                          'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Continue with Google',
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: Color(0xFFC6C6CD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bottom Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF45464D), // on-surface-variant
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF006A61), // secondary
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? trailingAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
            ?trailingAction,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB), // surface-bright
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC6C6CD)), // outline-variant
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF76777D).withValues(alpha: 0.7)),
              prefixIcon: Icon(icon, color: const Color(0xFF76777D), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
