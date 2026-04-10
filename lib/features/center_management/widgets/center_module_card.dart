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

    return GestureDetector(
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
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.96 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.black,
                  AppColors.black.withOpacity(0.92),
                ],
              ),
              border: Border.all(
                color: _pressed
                    ? AppColors.gold
                    : AppColors.gold.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _pressed
                      ? AppColors.gold.withOpacity(0.25)
                      : Colors.black.withOpacity(0.25),
                  blurRadius: _pressed ? 20 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(_pressed ? 0.3 : 0.15),
                        AppColors.gold.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    module.icon,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  safeTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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

                const SizedBox(height: 10),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  width: _pressed ? 40 : 20,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}