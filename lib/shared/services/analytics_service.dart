import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';

class AnalyticsService {

  static Future<void> logEvent(
    String name, {
    Map<String, Object?>? params,
  }) async {
    try {
      await FirebaseInit.init();

      await FirebaseService.refreshCurrentUser();

      final uid = FirebaseService.auth.currentUser?.uid ?? "";

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": name,
        "userId": uid,
        "courseId": params?["courseId"] ?? "",
        "lessonId": params?["lessonId"] ?? "",
        "extra": params ?? {},
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Analytics Error: $e");
    }
  }

  static Future<void> logEventAdvanced({
    required String type,
    String? userId,
    String? courseId,
    String? lessonId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await FirebaseInit.init();

      await FirebaseService.refreshCurrentUser();

      final uid = userId ?? FirebaseService.auth.currentUser?.uid ?? "";

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": type,
        "userId": uid,
        "courseId": courseId ?? "",
        "lessonId": lessonId ?? "",
        "extra": extra ?? {},
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Analytics Error: $e");
    }
  }

  static Future<void> logScreen(String name) async {
    await logEvent("screen_view", params: {"screen": name});
  }

  static Future<void> logCourseView(String courseId, {String? title}) async {
    await logEvent("course_view", params: {
      "courseId": courseId,
      "title": title ?? "",
    });
  }

  static Future<void> logPurchase(int amount, {String? courseId}) async {
    await logEvent("purchase", params: {
      "amount": amount,
      "courseId": courseId ?? "",
    });
  }
}