import 'package:flutter/material.dart';

import '../../core/colors.dart';

class HomeHero extends StatefulWidget {
  final String userName;
  final VoidCallback onStartTap;

  const HomeHero({
    super.key,
    required this.userName,
    required this.onStartTap,
  });

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  late Animation<double> _float;

  bool hovered = false;
  bool pressed = false;

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "صباح الخير ☀️";
    if (h < 18) return "مساء الخير 🌤";
    return "مساء الخير 🌙";
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _float = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String safeName =
        widget.userName.trim().isEmpty ? "أهلاً بيك" : widget.userName.trim();

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          hovered = true;
          _updateState();
        },
        onExit: (_) {
          hovered = false;
          pressed = false;
          _updateState();
        },
        child: GestureDetector(
          onTapDown: (_) {
            pressed = true;
            _updateState();
          },
          onTapUp: (_) {
            pressed = false;
            _updateState();
          },
          onTapCancel: () {
            pressed = false;
            _updateState();
          },
          onTap: () {
            try {
              if (!mounted) return;
              if (!context.mounted) return;
              widget.onStartTap();
            } catch (_) {}
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: pressed
                    ? 0.97
                    : hovered
                        ? 1.02
                        : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(0.0, hovered ? -_float.value : 0.0),
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(15, 10, 15, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(
                            alpha: hovered ? _glow.value : 0.25),
                        blurRadius: hovered ? 30 : 20,
                        spreadRadius: hovered ? 2 : 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(
                                    alpha: 0.1 + _glow.value * 0.25),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: -20,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(
                                    alpha: 0.08 + _glow.value * 0.2),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: hovered
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: hovered ? 19 : 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    child: Text(
                                      "أهلاً، $safeName",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "جاهز تكمل وتنجح؟ 🔥",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: pressed
                                ? 0.9
                                : hovered
                                    ? 1.05
                                    : 1,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () {
                                  try {
                                    if (!mounted) return;
                                    if (!context.mounted) return;
                                    widget.onStartTap();
                                  } catch (_) {}
                                },
                                child: const Row(
                                  children: [
                                    Text(
                                      "ابدأ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_ios, size: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}