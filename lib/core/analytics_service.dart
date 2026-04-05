import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AnalyticsService {

  static Future<void> init() async {
    try {
      debugPrint("🔥 Analytics Initialized");
    } catch (e) {
      debugPrint("🔥 Analytics Init Error: $e");
    }
  }

  static Future<void> logEvent(String name,
      {Map<String, Object?>? params}) async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": name,
        "userId": user?.uid,
        "params": params ?? {},
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Analytics Event Error: $e");
    }
  }

  static Future<void> logScreen(String name) async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "screen_view",
        "screen": name,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Screen Error: $e");
    }
  }

  static Future<void> logLogin() async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "login",
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Login Error: $e");
    }
  }

  static Future<void> logCourseView(String courseId, {String? title}) async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "course_view",
        "courseId": courseId,
        "courseTitle": title,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "course_view_extra",
        "courseId": courseId,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Course View Error: $e");
    }
  }

  static Future<void> logLessonOpen(String lessonId, {String? courseId}) async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "lesson_open",
        "lessonId": lessonId,
        "courseId": courseId,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Lesson Open Error: $e");
    }
  }

  static Future<void> logPurchase(int amount, {String? courseId}) async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "purchase",
        "amount": amount,
        "courseId": courseId,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "purchase_log",
        "amount": amount,
        "courseId": courseId,
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Purchase Error: $e");
    }
  }

  static Future<void> logRegister() async {
    try {

      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("analytics_events").add({
        "type": "register",
        "userId": user?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Register Error: $e");
    }
  }

  static Future<void> trackUserActive() async {
    try {
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