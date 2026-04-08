// 🔥 IMPORTS FIRST
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AnalyticsService {

  static bool _locked = false;
  static DateTime? _lastEventTime;

  static bool _canLog() {
    final now = DateTime.now();

    if (_locked) return false;

    if (_lastEventTime != null &&
        now.difference(_lastEventTime!).inMilliseconds < 300) {
      return false;
    }

    _lastEventTime = now;
    return true;
  }

  static Future<void> init() async {
    try {
      debugPrint("🔥 Analytics Initialized");
    } catch (e) {
      debugPrint("🔥 Analytics Init Error: $e");
    }
  }

  static Future<void> _log(Map<String, dynamic> data) async {
    try {

      if (!_canLog()) return;

      final user = FirebaseService.auth.currentUser;
      final firestore = FirebaseService.firestore;

      final payload = {
        ...data,
        "userId": user?.uid ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      await firestore.collection("analytics_events").add(payload);

    } catch (e) {
      debugPrint("🔥 Analytics Error: $e");
    }
  }

  static Future<void> logEvent(String name,
      {Map<String, Object?>? params}) async {

    await _log({
      "type": name,
      "params": params ?? {},
    });
  }

  static Future<void> logScreen(String name) async {
    await _log({
      "type": "screen_view",
      "screen": name,
    });
  }

  static Future<void> logLogin() async {
    await _log({
      "type": "login",
    });
  }

  static Future<void> logRegister() async {
    await _log({
      "type": "register",
    });
  }

  static Future<void> logCourseView(String courseId, {String? title}) async {

    final firestore = FirebaseService.firestore;

    try {

      if (!_canLog()) return;

      final user = FirebaseService.auth.currentUser;

      final baseData = {
        "courseId": courseId,
        "courseTitle": title ?? "",
        "userId": user?.uid ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      final ref1 = firestore.collection("analytics_events").doc();
      final ref2 = firestore.collection("analytics_events").doc();

      batch.set(ref1, {
        ...baseData,
        "type": "course_view",
      });

      batch.set(ref2, {
        ...baseData,
        "type": "course_view_extra",
      });

      await batch.commit();

    } catch (e) {
      debugPrint("🔥 Course View Error: $e");
    }
  }

  static Future<void> logLessonOpen(String lessonId, {String? courseId}) async {
    await _log({
      "type": "lesson_open",
      "lessonId": lessonId,
      "courseId": courseId ?? "",
    });
  }

  static Future<void> logPurchase(int amount, {String? courseId}) async {

    final firestore = FirebaseService.firestore;

    try {

      if (!_canLog()) return;

      final user = FirebaseService.auth.currentUser;

      final baseData = {
        "amount": amount,
        "courseId": courseId ?? "",
        "userId": user?.uid ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      final ref1 = firestore.collection("analytics_events").doc();
      final ref2 = firestore.collection("analytics_events").doc();

      batch.set(ref1, {
        ...baseData,
        "type": "purchase",
      });

      batch.set(ref2, {
        ...baseData,
        "type": "purchase_log",
      });

      await batch.commit();

    } catch (e) {
      debugPrint("🔥 Purchase Error: $e");
    }
  }

  static Future<void> trackUserActive() async {

    try {

      if (!_canLog()) return;

      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "active_user",
        "userId": user.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint("🔥 Active User Error: $e");
    }
  }

  static Future<int> getCourseViews(String courseId) async {
    try {
      final snap = await FirebaseService.firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "course_view")
          .where("courseId", isEqualTo: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getCoursePurchases(String courseId) async {
    try {
      final snap = await FirebaseService.firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "purchase")
          .where("courseId", isEqualTo: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}