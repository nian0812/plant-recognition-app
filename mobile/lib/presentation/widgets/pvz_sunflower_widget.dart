import 'dart:math' as math;
import 'package:flutter/material.dart';

class PvZSunflowerWidget extends StatefulWidget {
  final double size;
  const PvZSunflowerWidget({super.key, this.size = 110.0});

  @override
  State<PvZSunflowerWidget> createState() => _PvZSunflowerWidgetState();
}

class _PvZSunflowerWidgetState extends State<PvZSunflowerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1400ms PvZ signature bounce cycle (~85-90 BPM)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value; // 0.0 -> 1.0

        // 1. Tilt sway angle (Left at t=0.25, Right at t=0.75)
        final double angle = math.sin(t * 2 * math.pi) * 0.16; // ~9.2 deg

        // 2. Bounce translation Y (2 bounces per sway cycle)
        final double translateY = -math.sin(t * 4 * math.pi).abs() * 7.0;

        // 3. Squash & stretch effect
        final double bouncePhase = math.sin(t * 4 * math.pi);
        final double scaleY = 1.0 + (bouncePhase * 0.07);
        final double scaleX = 1.0 - (bouncePhase * 0.05);

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom shadow expanding and contracting
            Transform.scale(
              scaleX: 1.0 + (bouncePhase * 0.14),
              scaleY: 1.0 - (bouncePhase * 0.08),
              child: Container(
                width: widget.size * 0.52,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Animated character
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(0.0, translateY, 0.0)
                ..rotateZ(angle)
                ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1.0)),
              child: child,
            ),
          ],
        );
      },
      child: Image.asset(
        'assets/images/pvz_sunflower.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          child: const Text('🌻', style: TextStyle(fontSize: 48)),
        ),
      ),
    );
  }
}
