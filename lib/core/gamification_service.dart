// 🔥 GAMIFICATION SERVICE (XP + LEVEL SYSTEM)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class GamificationService {

  /// 🔥 حساب الليفل
  static int getLevel(int xp) {
    return (xp / 100).floor(); // كل 100 نقطة = level
  }

  /// 🔥 إضافة نقاط
  static Future addXP({
    required String userId,
    required int points,
  }) async {

    try {

      final ref = FirebaseService.firestore
          .collection("users")
          .doc(userId);

      final doc = await ref.get();

      int currentXP = 0;

      if (doc.exists) {
        currentXP = doc.data()?['xp'] ?? 0;
      }

      int newXP = currentXP + points;

      await ref.set({
        "xp": newXP,
        "level": getLevel(newXP),
      }, SetOptions(merge: true));

    } catch (_) {}
  }
}