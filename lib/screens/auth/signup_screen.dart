import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms and Privacy Policy')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().signup(name, email, password);
      // MainNavigationScreen is handled by AuthWrapper on state change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
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
    _nameController.dispose();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile Logo
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Color(0xFF131B2E), size: 28), // primary-container
                      const SizedBox(width: 8),
                      Text(
                        'ScanSpend',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF131B2E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Header
                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF45464D), // on-surface-variant
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form
                  _buildTextField(theme, _nameController, 'Full Name', 'Jane Doe', Icons.person_outline),
                  const SizedBox(height: 24),
                  _buildTextField(theme, _emailController, 'Email', 'jane@company.com', Icons.mail_outline),
                  const SizedBox(height: 24),
                  _buildTextField(
                    theme,
                    _passwordController,
                    'Password',
                    '••••••••',
                    Icons.lock_outline,
                    isPassword: true,
                    suffixIcon: Icons.visibility_off_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Terms Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFF006A61), // secondary
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF45464D), // on-surface-variant
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(text: 'Terms', style: TextStyle(color: Color(0xFF006A61), decoration: TextDecoration.underline)),
                              TextSpan(text: ' & '),
                              TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF006A61), decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A61), // secondary
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 2,
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
                                'Create Account',
                                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFC6C6CD))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or sign up with',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF76777D), // outline
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFC6C6CD))),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Social Sign Up
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading ? null : _handleGoogleSignup,
                    icon: Image.network(
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Google',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Color(0xFFC6C6CD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF45464D), // on-surface-variant
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Login',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF131B2E), // primary-container
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
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, TextEditingController controller, String label, String hint, IconData prefixIcon, {bool isPassword = false, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF45464D)),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // surface-container-lowest
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFC6C6CD)), // outline-variant
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF76777D).withValues(alpha: 0.5)),
              prefixIcon: Icon(prefixIcon, color: const Color(0xFF76777D), size: 20),
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF76777D), size: 20) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
