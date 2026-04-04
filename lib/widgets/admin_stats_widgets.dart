import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// 🔥🔥🔥 UPGRADE LAYER (NO DELETE - ADDED ABOVE)
class StatCardWrapper extends StatefulWidget {
  final Widget child;
  const StatCardWrapper({super.key, required this.child});

  @override
  State<StatCardWrapper> createState() => _StatCardWrapperState();
}

class _StatCardWrapperState extends State<StatCardWrapper>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> scale;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    scale = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    fade = Tween(begin: 0.0, end: 1.0).animate(controller);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}

/// 🔥 GLOW EFFECT
BoxDecoration _enhancedDecoration(bool highlight, Color color) {
  return AppColors.premiumCard.copyWith(
    gradient: highlight
        ? LinearGradient(
            colors: [
              color.withOpacity(0.15),
              Colors.black.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null,
    border: Border.all(
      color: highlight ? color.withOpacity(0.4) : Colors.transparent,
      width: 1,
    ),
    boxShadow: [
      if (highlight)
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 10,
        ),
    ],
  );
}

/// 🔥 ICON CONTAINER
Widget _iconBox(IconData icon, Color color, bool highlight) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      color: color,
      size: highlight ? 30 : 24,
    ),
  );
}

/// 🔥🔥🔥 END UPGRADE LAYER

Widget statCard(
  String title,
  int value,
  IconData icon,
  Color color, {
  bool highlight = false,
  required String Function(int) format,
}) {
  return StatCardWrapper(
    child: RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _enhancedDecoration(highlight, color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            _iconBox(icon, color, highlight),

            const SizedBox(height: 8),

            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 400),
              builder: (context, val, _) {
                return Text(
                  format(val),
                  style: TextStyle(
                    color: color,
                    fontSize: highlight ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 🔥 MINI STAT UPGRADE
Widget miniStat(String title, String value, Color color) {
  return RepaintBoundary(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        children: [

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.tryParse(value.replaceAll(",", "")) ?? 0),
            duration: const Duration(milliseconds: 400),
            builder: (context, val, _) {
              return Text(
                val.toInt().toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}