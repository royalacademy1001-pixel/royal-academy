import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import 'package:flutter/material.dart';

class LessonXP {
  static Future<void> reward(String lessonId) async {
    try {
      if (!FirebaseService.canAddXP(lessonId)) return;

      await FirebaseService.addXP(
        AppConstants.xpPerLesson,
      );
    } catch (e) {
      debugPrint("XP Error: $e");
    }
  }
}