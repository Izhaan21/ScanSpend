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
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all required fields.', isError: true);
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar('Please agree to the Terms of Service & Privacy Policy.', isError: true);
      return;
    }

    try {
      await context.read<AuthProvider>().signup(name, email, password);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
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
          // Anchored behind the title and registration form fields to enhance clarity and focus
          Positioned(
            top: size.height * 0.12,
            left: -40,
            right: -40,
            child: Center(
              child: Container(
                width: size.width * 1.1,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.25), // Electric Blue Core
                      const Color(0xFF06B6D4).withValues(alpha: 0.12), // Turquoise cyan diffusion
                      const Color(0x00090E17), // Fades into obsidian canvas
                    ],
                    stops: const [0.15, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Supporting ambient glow behind the action buttons at the base of the form
          Positioned(
            bottom: size.height * 0.08,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        
                        // Editorial Headline Typography (Spotlit by ambient background glow)
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
                              TextSpan(text: 'Create your\n'),
                              TextSpan(
                                text: 'smart account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: '.',
                                style: TextStyle(
                                  color: _primary, // Electric Blue dot accent
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Automate expense tracking & scan receipts instantly with AI.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _textMuted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Full Name Field
                        Text(
                          'FULL NAME',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: 'John Doe',
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 20),

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
                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'PASSWORD',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: 'At least 8 characters',
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
                        const SizedBox(height: 22),

                        // Terms & Privacy Policy Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: _secondary,
                                checkColor: _bg,
                                side: const BorderSide(color: Color(0xFF334155), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (val) {
                                  setState(() {
                                    _agreedToTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _agreedToTerms = !_agreedToTerms;
                                  });
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: _textMuted, fontSize: 13.5, height: 1.3),
                                    children: const [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(color: _secondary, fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(color: _secondary, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

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
                            onPressed: authProvider.isLoading ? null : _handleSignup,
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
                                        'CREATE ACCOUNT',
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
                        const SizedBox(height: 26),

                        // Or Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: _border, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR REGISTER WITH',
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
                        const SizedBox(height: 22),

                        // Google Authentication Pill
                        InkWell(
                          onTap: authProvider.isLoading ? null : _handleGoogleSignup,
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
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFFEA4335),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
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
                        const SizedBox(height: 32),

                        // Footer Switcher
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: _textMuted, fontSize: 15),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Log In',
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
