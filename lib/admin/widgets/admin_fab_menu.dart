import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../utils/admin_utils.dart';

class AdminFabMenu {
  static void open({
    required BuildContext context,
    required Future<void> Function() refresh,
    required Future<String?> Function() pickLesson,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🚀 إضافة جديدة",
                    style: TextStyle(color: AppColors.gold, fontSize: 20)),
              ],
            ),
          ),
        );
      },
    );
  }
}