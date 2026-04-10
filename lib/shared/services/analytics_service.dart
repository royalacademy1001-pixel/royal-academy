import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';

class AnalyticsService {
  static Future<void> logEvent({
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
}