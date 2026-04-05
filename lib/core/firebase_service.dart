// 🔥 IMPORTS FIRST
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 IMPORTANT
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart'; // 🔥🔥🔥 FIX مهم جدا

import 'constants.dart';


/// 🔥🔥🔥 FIREBASE SUPER ENGINE UPGRADED FINAL 🔥🔥🔥

class CacheManager {
  static final Map<String, DateTime> _times = {};

  static bool isValid(String key, int seconds) {
    if (!_times.containsKey(key)) return false;
    return DateTime.now()
            .difference(_times[key]!)
            .inSeconds <
        seconds;
  }

  static void set(String key) {
    _times[key] = DateTime.now();
  }

  static void clear() {
    _times.clear();
  }
}

/// 🔥🔥🔥 INIT FIREBASE (FIXED)
class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint("🔥 Firebase Initialized");
    } catch (e) {
      debugPrint("🔥 Firebase Init Error: $e");
    }
  }
}

/// 🔥 SAFE FIRESTORE
Future<T?> safeFirestoreCall<T>(Future<T> Function() call) async {
  try {
    await FirebaseInit.init();
    return await call();
  } catch (e) {
    debugPrint("🔥 Retry Firestore...");
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      await FirebaseInit.init();
      return await call();
    } catch (e) {
      debugPrint("🔥 Final Firestore Error: $e");
      return null;
    }
  }
}

/// 🔥 TIMEOUT
Future<T?> safeTimeout<T>(Future<T?> Function() call) async {
  try {
    await FirebaseInit.init();
    return await call().timeout(const Duration(seconds: 10));
  } catch (_) {
    debugPrint("⏱ Timeout");
    return null;
  }
}


class FirebaseService {

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static Future<User?> refreshCurrentUser() async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return null;

      await user.reload();

      final refreshed = auth.currentUser;
      if (refreshed == null) return null;

      await refreshed.getIdToken(true);
      return refreshed;
    } catch (e) {
      debugPrint("🔥 Auth Refresh Error: $e");
      return auth.currentUser;
    }
  }

  static Future<void> addXP(int xp) async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null || xp <= 0) return;

      final ref = firestore.collection(AppConstants.users).doc(user.uid);

      await safeFirestoreCall(() => ref.update({
            "xp": FieldValue.increment(xp),
            "lastXPUpdate": FieldValue.serverTimestamp(),
          }));
    } catch (e) {
      debugPrint("🔥 XP Error: $e");
    }
  }

  static Future<void> updateStreak() async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return;

      final ref = firestore.collection(AppConstants.users).doc(user.uid);

      final doc = await safeFirestoreCall(() => ref.get());
      if (doc == null) return;

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      DateTime? last;

      if (doc.data()?['lastLogin'] != null) {
        last = DateTime.tryParse(doc['lastLogin'].toString());
      }

      int streak = doc.data()?['streak'] ?? 0;

      if (last != null) {
        DateTime lastDay = DateTime(last.year, last.month, last.day);

        if (today.difference(lastDay).inDays == 1) {
          streak++;
        } else if (today.difference(lastDay).inDays > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }

      await safeFirestoreCall(() => ref.set({
            "streak": streak,
            "lastLogin": now.toIso8601String(),
          }, SetOptions(merge: true)));

      await addXP(5);
    } catch (e) {
      debugPrint("🔥 Streak Error: $e");
    }
  }

  static Future<void> safeUpdate(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseInit.init();
      await safeFirestoreCall(() =>
          ref.set(data, SetOptions(merge: true)));
    } catch (e) {
      debugPrint("🔥 Safe Update Error: $e");
    }
  }

  static final Map<String, DateTime> _xpLock = {};

  static bool canAddXP(String key) {
    final now = DateTime.now();

    if (_xpLock.containsKey(key)) {
      if (now.difference(_xpLock[key]!).inSeconds < 10) {
        return false;
      }
    }

    _xpLock[key] = now;
    return true;
  }

  static Map<String, dynamic>? _userCache;
  static DateTime? _lastFetchTime;

  static bool _notificationsInitialized = false;
  static bool _fetchingUser = false;
  static Completer<Map<String, dynamic>>? _userCompleter;

  static String? _lastTokenSaved;

  static const int _cacheSeconds = AppConstants.cacheSeconds;

  static String fixImage(String url) {
    if (url.isEmpty) return url;

    try {
      if (url.startsWith("gs://")) {
        return url;
      }

      if (!url.contains("http")) return "";

      if (!url.contains("v=")) {
        url = "$url?v=${DateTime.now().millisecondsSinceEpoch}";
      }

      return url;

    } catch (e) {
      debugPrint("🔥 Image Fix Error: $e");
      return url;
    }
  }

  static Future<void> initNotifications() async {
    try {
      await FirebaseInit.init();

      if (_notificationsInitialized || kIsWeb) return;

      _notificationsInitialized = true;

      await refreshCurrentUser();
      await messaging.requestPermission();
      await updateToken();

      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint("🔔 ${message.notification?.title}");
      });

      await subscribeToTopic(AppConstants.topicAllUsers);

    } catch (e) {
      debugPrint("🔥 Notification Error: $e");
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseInit.init();

      if (!kIsWeb) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      }
    } catch (e) {
      debugPrint("🔥 Topic Subscribe Error: $e");
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      await FirebaseInit.init();

      await refreshCurrentUser();

      final user = auth.currentUser;
      if (user == null || token.isEmpty) return;

      if (_lastTokenSaved == token) return;
      _lastTokenSaved = token;

      final ref = firestore
          .collection(AppConstants.users)
          .doc(user.uid);

      await safeFirestoreCall(() => ref.set({
            "fcmTokens": FieldValue.arrayUnion([token]),
          }, SetOptions(merge: true)));
    } catch (e) {
      debugPrint("🔥 Token Error: $e");
    }
  }

  static Future<void> updateToken() async {
    try {
      await FirebaseInit.init();

      if (kIsWeb) return;

      await refreshCurrentUser();

      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint("🔥 Update Token Error: $e");
    }
  }

  static Future<void> logout() async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;

      if (!kIsWeb) {
        await messaging.deleteToken();
      }

      if (user != null) {
        await firestore
            .collection(AppConstants.users)
            .doc(user.uid)
            .update({
          "fcmTokens": [],
        });
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }

    clearUserCache();
    CacheManager.clear();
    _notificationsInitialized = false;
    _lastTokenSaved = null;

    await auth.signOut();
  }

  static Future<Map<String, dynamic>> getUserData({
    bool refresh = false,
  }) async {
    final now = DateTime.now();

    try {
      await FirebaseInit.init();

      if (!refresh &&
          _userCache != null &&
          _lastFetchTime != null &&
          now.difference(_lastFetchTime!).inSeconds < _cacheSeconds) {
        return _userCache!;
      }

      if (_fetchingUser && _userCompleter != null) {
        return _userCompleter!.future;
      }

      _fetchingUser = true;
      _userCompleter = Completer();

      await refreshCurrentUser();

      final user = auth.currentUser;

      if (user == null) {
        _completeUser({});
        return {};
      }

      final doc = await safeTimeout(() =>
          safeFirestoreCall(() =>
              firestore.collection(AppConstants.users).doc(user.uid).get()));

      _userCache = doc?.data() ?? {};
      _lastFetchTime = now;

      _completeUser(_userCache!);

      return _userCache!;

    } catch (e) {
      debugPrint("🔥 getUserData Error: $e");
      _completeUser({});
      return {};
    }
  }

  static Future<void> logEvent({
    required String type,
    String? userId,
    String? courseId,
    String? lessonId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await FirebaseInit.init();

      await refreshCurrentUser();

      final uid = userId ?? auth.currentUser?.uid ?? "";

      await firestore.collection("analytics_events").add({
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

  static Future<int> getCourseStudents(String courseId) async {
    try {
      await FirebaseInit.init();

      final snap = await firestore
          .collection(AppConstants.users)
          .where("enrolledCourses", arrayContains: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getCourseViews(String courseId) async {
    try {
      await FirebaseInit.init();

      final snap = await firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "course_view")
          .where("courseId", isEqualTo: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getInstructorTotalStudents(String instructorId) async {
    try {
      await FirebaseInit.init();

      final courses = await firestore
          .collection(AppConstants.courses)
          .where("instructorId", isEqualTo: instructorId)
          .get();

      int total = 0;

      for (var c in courses.docs) {
        final count = await getCourseStudents(c.id);
        total += count;
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getInstructorTotalViews(String instructorId) async {
    try {
      await FirebaseInit.init();

      final courses = await firestore
          .collection(AppConstants.courses)
          .where("instructorId", isEqualTo: instructorId)
          .get();

      int total = 0;

      for (var c in courses.docs) {
        final count = await getCourseViews(c.id);
        total += count;
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  static void _completeUser(Map<String, dynamic> data) {
    _fetchingUser = false;

    if (_userCompleter != null &&
        !_userCompleter!.isCompleted) {
      _userCompleter!.complete(data);
    }
  }

  static void clearUserCache() {
    _userCache = null;
    _lastFetchTime = null;
  }

  static bool hasRole(String role) {
    if (_userCache == null) return false;

    if (role == "admin") return _userCache?['isAdmin'] == true;
    if (role == "instructor") return _userCache?['instructorApproved'] == true;
    if (role == "vip") return _userCache?['subscribed'] == true;
    if (role == "user") return _userCache?['isAdmin'] != true;

    return false;
  }

  static bool canAccessNavItem(Map<String, dynamic> item) {
    List roles = item['roles'] ?? [];

    if (roles.contains("all")) return true;

    for (var r in roles) {
      if (hasRole(r.toString())) return true;
    }

    return false;
  }
}