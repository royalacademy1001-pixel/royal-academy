import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';

class HomeAppBar extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? notificationStream;
  final VoidCallback onNotificationsTap;

  const HomeAppBar({
    super.key,
    required this.notificationStream,
    required this.onNotificationsTap,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  late Animation<double> _pulse;

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

    _pulse = Tween<double>(begin: 1, end: 1.08).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SliverAppBar(
          expandedHeight: 105,
          floating: true,
          pinned: true,
          backgroundColor: Colors.black.withOpacity(0.7),
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10 + (_glow.value * 12),
                sigmaY: 10 + (_glow.value * 12),
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: hovered ? 19 : 18,
                    shadows: [
                      Shadow(
                        color: AppColors.gold.withValues(alpha: _glow.value),
                        blurRadius: 14,
                      )
                    ],
                  ),
                  child: Text(greeting()),
                ),
              ),
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.notificationStream,
              builder: (context, snapshot) {
                final user = FirebaseService.auth.currentUser;
                int count = 0;

                if (snapshot.hasData && user != null) {
                  count = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    return (data['userId'] == user.uid ||
                            data['type'] == "all") &&
                        !(data['seen'] ?? false);
                  }).length;
                }

                return RepaintBoundary(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
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
                          widget.onNotificationsTap();
                        } catch (_) {}
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: pressed
                            ? 0.9
                            : hovered
                                ? _pulse.value
                                : 1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(
                                        alpha: hovered
                                            ? _glow.value
                                            : _glow.value * 0.5),
                                    blurRadius: hovered ? 24 : 16,
                                    spreadRadius: hovered ? 1.5 : 0,
                                  )
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: hovered ? 1.1 : 1,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.7),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      count > 9 ? "9+" : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        );
      },
    );
  }
}