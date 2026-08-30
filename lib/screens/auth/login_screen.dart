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
  bool _obscurePassword = true;

  // ── Executive Fintech AI Palette ─────────────────────────────────────────────
  static const Color _primary   = Color(0xFF2563EB); // Vibrant Electric Blue
  static const Color _secondary = Color(0xFF06B6D4); // Turquoise Cyan Accent
  static const Color _bg        = Color(0xFF090E17); // Deep Obsidian Slate Canvas
  static const Color _inputBg   = Color(0xFF0F172A); // High-Precision Dark Inset
  static const Color _text      = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color _textMuted = Color(0xFF94A3B8); // Soft Slate Muted Text
  static const Color _border    = Color(0xFF223046); // Subtle Glowing Border Slate

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all required fields.', isError: true);
      return;
    }

    try {
      await context.read<AuthProvider>().login(email, password);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        backgroundColor: isError ? const Color(0xFFE11D48) : _primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Meaningful Focal Atmospheric Glows ─────────────────────────────
          // Placed directly behind the headline text and primary input fields to spotlight functionality
          Positioned(
            top: size.height * 0.14,
            left: -40,
            right: -40,
            child: Center(
              child: Container(
                width: size.width * 1.1,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.25), // Electric Blue spotlight
                      const Color(0xFF06B6D4).withValues(alpha: 0.12), // Turquoise cyan diffusion
                      const Color(0x00090E17), // Fades into deep obsidian canvas
                    ],
                    stops: const [0.15, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Subtle supporting glow behind primary submit & authentication controls
          Positioned(
            bottom: size.height * 0.08,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.18),
                    const Color(0x00090E17),
                  ],
                ),
              ),
            ),
          ),

          // ── Unconfined Executive Layout ────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar with cleanly solitary Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF334155), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: _text, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Scrollable Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        
                        // Editorial Headline Typography (Spotlit by background glow)
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: const Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w300,
                              fontSize: 34,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                            children: const [
                              TextSpan(text: 'Welcome back to\n'),
                              TextSpan(
                                text: 'ScanSpend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: '.',
                                style: TextStyle(
                                  color: _secondary, // Turquoise Cyan dot accent
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Access AI-driven expense intelligence & real-time analytics.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _textMuted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Email Address Field
                        Text(
                          'EMAIL ADDRESS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Password Field & Forgot Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PASSWORD',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showSnackBar('Password reset verification link sent (demo)');
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: _secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: _textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                            ),
                          ),
                        ),
                        const SizedBox(height: 38),

                        // Primary Action Pill Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            boxShadow: [],
                          ),
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Or Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: _border, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: _border, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Authentication Pill
                        InkWell(
                          onTap: authProvider.isLoading ? null : _handleGoogleLogin,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFF334155), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/google_logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Footer Switcher
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New to ScanSpend? ",
                                  style: TextStyle(color: _textMuted, fontSize: 15),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: _secondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w400, fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: _textMuted, size: 22),
      ),
      suffixIcon: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon) : null,
      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _secondary, width: 2),
      ),
    );
  }
}
