// 🔥 FINAL SPLASH (PRO ANIMATION FAST + PREMIUM)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔥 Pages
import 'login_page.dart';
import 'main_navigation_page.dart';

// 🔥 Design
import 'core/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  StreamSubscription<User?>? sub;
  bool navigated = false;

  late AnimationController controller;
  late Animation<double> fade;
  late Animation<double> scale;
  late Animation<double> glow;

  final DateTime startTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startApp();
    });
  }

  Future<void> startApp() async {

    await Future.delayed(const Duration(milliseconds: 300));

    try {

      sub = FirebaseAuth.instance.authStateChanges().listen((user) async {

        if (!mounted || navigated) return;

        navigated = true;

        final elapsed =
            DateTime.now().difference(startTime).inMilliseconds;

        if (elapsed < 700) {
          await Future.delayed(
              Duration(milliseconds: 700 - elapsed));
        }

        await sub?.cancel();
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || navigated) return;
        navigated = true;
      });

    } catch (_) {}
  }

  void _goTo(Widget page) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {

          final fadeAnim =
              Tween(begin: 0.0, end: 1.0).animate(anim);

          final slideAnim = Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(anim);

          return FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    sub?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.black,
              Color(0xFF1A1A1A),
              AppColors.black,
            ],
          ),
        ),

        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  AnimatedBuilder(
                    animation: glow,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.4 * glow.value),
                              blurRadius: 40 * glow.value,
                              spreadRadius: 5 * glow.value,
                            )
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      "assets/logo.png",
                      height: 100,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Royal Academy",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "ابدأ رحلتك التعليمية 🚀",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}