import 'package:flutter/material.dart';
import 'colors.dart';

BoxDecoration royalCardDecoration() {
  return BoxDecoration(
    color: AppColors.card,

    borderRadius: BorderRadius.circular(20),

    // ✨ البوردر الدهبي
    border: Border.all(
      color: AppColors.gold,
      width: 1.5,
    ),

    // 🔥 الجلو (أهم حاجة)
    boxShadow: [
      BoxShadow(
        color: AppColors.gold.withOpacity(0.4),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );
}