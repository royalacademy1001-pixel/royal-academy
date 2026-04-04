// 🔥 FINAL PRO CUSTOM BUTTON (PRO MAX++ PREMIUM UPGRADE)

import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/press_effect.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final double height;
  final bool isLoading;

  /// 🔥 NEW
  final Widget? icon;
  final double radius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.height = 55,
    this.isLoading = false,

    /// 🔥 NEW
    this.icon,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;

    return PressEffect(
      enabled: !disabled,

      onTap: () {
        if (!disabled) onPressed?.call();
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        width: double.infinity,
        height: height,

        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.goldGradient,
          color: disabled ? Colors.grey.shade800 : null,

          borderRadius: BorderRadius.circular(radius),

          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),

        child: Stack(
          alignment: Alignment.center,
          children: [

            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: disabled ? 0.7 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.2),
                  ),
                ),
              ),
            ),

            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),

                child: isLoading
                    ? const SizedBox(
                        key: ValueKey("loading"),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        key: const ValueKey("text"),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          if (icon != null) ...[
                            icon!,
                            const SizedBox(width: 8),
                          ],

                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: disabled
                                  ? Colors.grey.shade300
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}