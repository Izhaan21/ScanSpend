import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A slow, 15-second loop that reverses, creating a continuous organic flow
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Base dark background (avoiding pure black for less smearing and softer feel)
        Container(color: const Color(0xFF070B14)),
        
        // 2. Animated Blob 1 (Electric Blue - Top Left)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Positioned(
              top: -size.height * 0.1 + (math.sin(_controller.value * math.pi) * 100),
              left: -size.width * 0.2 + (math.cos(_controller.value * math.pi) * 50),
              child: Container(
                width: size.width * 1.3,
                height: size.width * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.35), // Deep Electric Blue
                      const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            );
          },
        ),

        // 3. Animated Blob 2 (Subtle Cyan - Bottom Right)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Positioned(
              bottom: -size.height * 0.1 - (math.cos(_controller.value * math.pi) * 80),
              right: -size.width * 0.1 - (math.sin(_controller.value * math.pi) * 80),
              child: Container(
                width: size.width * 1.1,
                height: size.width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withValues(alpha: 0.25), // Cyan
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
        
        // 4. Animated Blob 3 (Deep Purple Accent - Drifting through center)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Positioned(
              top: size.height * 0.3 + (math.cos(_controller.value * math.pi * 2) * 60),
              left: size.width * 0.2 + (math.sin(_controller.value * math.pi * 2) * 60),
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.20), // Purple accent
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            );
          },
        ),

        // 5. Heavy Gaussian Blur to blend the blobs into a liquid mesh gradient
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),

        // 6. The actual foreground UI content
        widget.child,
      ],
    );
  }
}
