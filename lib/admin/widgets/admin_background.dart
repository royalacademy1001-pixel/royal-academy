import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/colors.dart';

class AdminBackground extends StatefulWidget {
  final Widget child;

  const AdminBackground({super.key, required this.child});

  @override
  State<AdminBackground> createState() => _AdminBackgroundState();
}

class _AdminBackgroundState extends State<AdminBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + value, -1),
                    end: Alignment(1, 1 - value),
                    colors: [
                      Colors.black,
                      const Color(0xFF0B0B0B),
                      const Color(0xFF050505),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -120,
              right: -120,
              child: _glowCircle(
                size: 320,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),

            Positioned(
              bottom: -140,
              left: -140,
              child: _glowCircle(
                size: 350,
                color: Colors.blue.withValues(alpha: 0.05),
              ),
            ),

            Positioned(
              top: 200,
              left: -100,
              child: _glowCircle(
                size: 250,
                color: Colors.purple.withValues(alpha: 0.04),
              ),
            ),

            widget.child,
          ],
        );
      },
    );
  }

  Widget _glowCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: const SizedBox(),
      ),
    );
  }
}