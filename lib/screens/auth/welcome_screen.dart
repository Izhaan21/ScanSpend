import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17), // Deep Obsidian Slate
      body: Stack(
        children: [
          // 1. Ambient Background Glow
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.2,
            right: -size.width * 0.2,
            child: Container(
              height: size.height * 0.65,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF2563EB), // Electric Blue core
                    Color(0xFF06B6D4), // Turquoise Cyan inner glow
                    Color(0x00090E17), // Transparent outer fade
                  ],
                  stops: [0.0, 0.45, 1.0],
                  radius: 0.85,
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            right: -size.width * 0.25,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF60A5FA).withValues(alpha: 0.35),
                    const Color(0x00090E17),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Editorial Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 1),

                    // 3. The Hero Blended 'S' Logo in Blue Orb
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Radiant Glowing Blue Orb Backdrop
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF2563EB), // Vibrant Electric Blue Core
                                    Color(0xFF06B6D4), // Cyan Luminous Halo
                                    Color(0x00090E17), // Fade to transparent
                                  ],
                                  stops: [0.15, 0.55, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                    blurRadius: 70,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            // Softly blended logo without borders or sharp edges
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.48,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.75, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.asset(
                                'assets/logo.png',
                                width: 170,
                                height: 170,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // High-Contrast Punchy Headline
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: const Color(0xFFE2E8F0), // Clean light slate
                          fontWeight: FontWeight.w300,
                          fontSize: 38,
                          height: 1.2,
                          letterSpacing: -0.8,
                        ),
                        children: const [
                          TextSpan(text: 'Scan receipts & track\nyour '),
                          TextSpan(
                            text: 'expenses',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: ' effortlessly\nwith AI!'),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Interactive Pill Nav Bar (Bottom Controls)
                    Row(
                      children: [
                        // Secondary "Log In" Pill with Touch Ripple Effect
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(33),
                          child: InkWell(
                            onTap: () {
                              // Fire and forget: trigger permission/GPS in the background
                              context.read<SettingsProvider>().triggerGPSCurrencyDetection(context: context);
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(33),
                            splashColor: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            highlightColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            child: Ink(
                              height: 66,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B), // Slate 800
                                borderRadius: BorderRadius.circular(33),
                                border: Border.all(color: const Color(0xFF334155), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  'Log In',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Animated Slide-To-Start Hero Capsule
                        Expanded(
                          child: _SlideToStartButton(
                            onSlideCompleted: () {
                              // Fire and forget: trigger permission/GPS in the background
                              context.read<SettingsProvider>().triggerGPSCurrencyDetection(context: context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}

// ── Interactive Animated Slide-To-Start Pill Widget ──────────────────────────
class _SlideToStartButton extends StatefulWidget {
  final VoidCallback onSlideCompleted;

  const _SlideToStartButton({required this.onSlideCompleted});

  @override
  State<_SlideToStartButton> createState() => _SlideToStartButtonState();
}

class _SlideToStartButtonState extends State<_SlideToStartButton>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        setState(() {});
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerCompletion() {
    if (_completed) return;
    _completed = true;
    widget.onSlideCompleted();
    
    // Automatically reset when navigating back
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _completed = false;
        _slideController.animateTo(0.0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const double trackHeight = 66.0;
        const double padding = 5.0;
        const double buttonSize = 56.0; // Perfect 56px circular action button
        final maxSlide = math.max(0.0, maxWidth - buttonSize - (padding * 2));
        final progress = _slideController.value;
        final currentSlidePx = maxSlide * progress;

        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (_completed) return;
          },
          onHorizontalDragUpdate: (details) {
            if (_completed || maxSlide <= 0) return;
            _slideController.value = (_slideController.value + details.delta.dx / maxSlide).clamp(0.0, 1.0);
          },
          onHorizontalDragEnd: (details) {
            if (_completed) return;
            final velocity = details.primaryVelocity ?? 0.0;
            if (_slideController.value > 0.55 || velocity > 350) {
              _slideController.animateTo(1.0, curve: Curves.easeOutCubic).then((_) => _triggerCompletion());
            } else {
              _slideController.animateTo(0.0, curve: Curves.easeOutCubic);
            }
          },
          onTap: () {
            if (_completed) return;
            _slideController.animateTo(1.0, curve: Curves.easeInOutCubic).then((_) => _triggerCompletion());
          },
          child: Container(
            height: trackHeight,
            padding: const EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.circular(trackHeight / 2),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Illuminated Trailing Progress Track behind Slider
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: currentSlidePx + buttonSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.8),
                          const Color(0xFF06B6D4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                    ),
                  ),
                ),

                // Centered Label ("Get Started")
                Center(
                  child: Opacity(
                    opacity: (1.0 - (progress * 1.8)).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 36.0, right: 28.0),
                      child: Text(
                        'Get Started',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated Pulsing Chevrons (Right edge)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: ((1.0 - progress) * _pulseAnimation.value).clamp(0.0, 1.0),
                          child: const Text(
                            '>>>',
                            style: TextStyle(
                              color: Color(0xFF06B6D4), // Turquoise cyan chevrons
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -2.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // The Complete, Unclipped Draggable White Action Circle
                Positioned(
                  left: currentSlidePx,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: progress * math.pi * 2, // Smooth animated rotation
                      child: Icon(
                        progress >= 0.95 ? Icons.check : Icons.arrow_forward_rounded,
                        color: const Color(0xFF0F172A), // Deep Slate Navy
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
