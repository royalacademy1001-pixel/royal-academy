import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AnalyticsService {

  static bool _locked = false;
  static DateTime? _lastEventTime;
  static final Map<String, DateTime> _eventLock = {};
  static final Map<String, int> _cacheCounts = {};

  static bool _canLog([String key = "global"]) {
    final now = DateTime.now();

    if (_locked) return false;

    if (_eventLock.containsKey(key)) {
      if (now.difference(_eventLock[key]!).inMilliseconds < 800) {
        return false;
      }
    }

    if (_lastEventTime != null &&
        now.difference(_lastEventTime!).inMilliseconds < 200) {
      return false;
    }

    _lastEventTime = now;
    _eventLock[key] = now;
    return true;
  }

  static Future<void> init() async {
    try {
      debugPrint("🔥 Analytics Initialized");
    } catch (e) {
      debugPrint("🔥 Analytics Init Error: $e");
    }
  }

  static Future<void> _log(Map<String, dynamic> data,
      {String key = "global"}) async {
    try {

      if (!_canLog(key)) return;

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
    }, key: name);
  }

  static Future<void> logScreen(String name) async {
    await _log({
      "type": "screen_view",
      "screen": name,
    }, key: "screen_$name");
  }

  static Future<void> logLogin() async {
    await _log({
      "type": "login",
    }, key: "login");
  }

  static Future<void> logRegister() async {
    await _log({
      "type": "register",
    }, key: "register");
  }

  static Future<void> logCourseView(String courseId, {String? title}) async {

    final firestore = FirebaseService.firestore;

    try {

      if (!_canLog("course_$courseId")) return;

      final user = FirebaseService.auth.currentUser;

      final baseData = {
        "courseId": courseId,
        "courseTitle": title ?? "",
        "userId": user?.uid ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      await firestore.collection("analytics_events").add({
        ...baseData,
        "type": "course_view",
      });

      _cacheCounts["views_$courseId"] =
          (_cacheCounts["views_$courseId"] ?? 0) + 1;

    } catch (e) {
      debugPrint("🔥 Course View Error: $e");
    }
  }

  static Future<void> logLessonOpen(String lessonId, {String? courseId}) async {
    await _log({
      "type": "lesson_open",
      "lessonId": lessonId,
      "courseId": courseId ?? "",
    }, key: "lesson_$lessonId");
  }

  static Future<void> logPurchase(int amount, {String? courseId}) async {

    final firestore = FirebaseService.firestore;

    try {

      if (!_canLog("purchase_$courseId")) return;

      final user = FirebaseService.auth.currentUser;

      final baseData = {
        "amount": amount,
        "courseId": courseId ?? "",
        "userId": user?.uid ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      await firestore.collection("analytics_events").add({
        ...baseData,
        "type": "purchase",
      });

      if (courseId != null) {
        _cacheCounts["purchase_$courseId"] =
            (_cacheCounts["purchase_$courseId"] ?? 0) + 1;
      }

    } catch (e) {
      debugPrint("🔥 Purchase Error: $e");
    }
  }

  static Future<void> trackUserActive() async {

    try {

      if (!_canLog("active")) return;

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

      if (_cacheCounts.containsKey("views_$courseId")) {
        return _cacheCounts["views_$courseId"]!;
      }

      final snap = await FirebaseService.firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "course_view")
          .where("courseId", isEqualTo: courseId)
          .get();

      final count = snap.docs.length;

      _cacheCounts["views_$courseId"] = count;

      return count;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getCoursePurchases(String courseId) async {
    try {

      if (_cacheCounts.containsKey("purchase_$courseId")) {
        return _cacheCounts["purchase_$courseId"]!;
      }

      final snap = await FirebaseService.firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "purchase")
          .where("courseId", isEqualTo: courseId)
          .get();

      final count = snap.docs.length;

      _cacheCounts["purchase_$courseId"] = count;

      return count;
    } catch (_) {
      return 0;
    }
  }
}