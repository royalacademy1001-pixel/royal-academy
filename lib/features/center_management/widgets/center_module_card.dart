import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../models/admin_module.dart';

class CenterModuleCard extends StatefulWidget {
  final AdminModule module;
  final VoidCallback onTap;

  const CenterModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  @override
  State<CenterModuleCard> createState() => _CenterModuleCardState();
}

class _CenterModuleCardState extends State<CenterModuleCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _onTapDown(_) {
    if (!mounted) return;
    setState(() => _pressed = true);
  }

  void _onTapUp(_) {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;

    final safeTitle = module.title.isEmpty ? "" : module.title;
    final safeSubtitle = module.subtitle.isEmpty ? "" : module.subtitle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          if (!mounted) return;
          widget.onTap();
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _pressed ? 0.9 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _pressed
                ? 0.9
                : _hovered
                    ? 1.08
                    : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              transform: Matrix4.identity()
                ..translate(0.0, _hovered ? -10.0 : 0.0)
                ..scale(_hovered ? 1.01 : 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.black,
                    AppColors.black.withOpacity(0.92),
                  ],
                ),
                border: Border.all(
                  color: _hovered
                      ? AppColors.gold
                      : (_pressed
                          ? AppColors.gold
                          : AppColors.gold.withOpacity(0.35)),
                  width: _hovered ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? AppColors.gold.withOpacity(0.55)
                        : (_pressed
                            ? AppColors.gold.withOpacity(0.25)
                            : Colors.black.withOpacity(0.3)),
                    blurRadius: _hovered ? 35 : (_pressed ? 22 : 12),
                    spreadRadius: _hovered ? 3 : 0,
                    offset: Offset(0, _hovered ? 18 : 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _hovered ? 1 : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: RadialGradient(
                            colors: [
                              AppColors.gold.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _hovered ? 66 : 56,
                        height: _hovered ? 66 : 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withOpacity(
                                  _hovered ? 0.5 : (_pressed ? 0.3 : 0.15)),
                              AppColors.gold.withOpacity(0.05),
                            ],
                          ),
                          boxShadow: _hovered
                              ? [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 3,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          module.icon,
                          color: AppColors.gold,
                          size: _hovered ? 34 : 28,
                        ),
                      ),

                      const SizedBox(height: 12),

                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: _hovered ? AppColors.gold : Colors.white,
                          fontSize: _hovered ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text(
                          safeTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        safeSubtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 12),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 4,
                        width: _hovered
                            ? 70
                            : (_pressed ? 45 : 20),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(10),
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
}