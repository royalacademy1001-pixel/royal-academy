import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'constants.dart';

import '../main.dart';
import '../course_details_page.dart';
import '../video_page.dart';

class NotificationsService {

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static bool _initialized = false;
  static String? _lastSavedToken;

  static Future<void> sendToAll({
    required String title,
    required String body,
  }) async {
    try {
      await sendNotification(
        title: title,
        body: body,
        data: {"type": "broadcast"},
      );
    } catch (e) {
      debugPrint("🔥 Broadcast Error: $e");
    }
  }

  static Future<void> sendDelayed({
    required String title,
    required String body,
    required Duration delay,
  }) async {
    Future.delayed(delay, () {
      sendNotification(title: title, body: body);
    });
  }

  static Future<void> markAsSeen(String notificationId) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .doc(notificationId)
          .update({"seen": true});
    } catch (e) {
      debugPrint("🔥 Seen Error: $e");
    }
  }

  static void safeNavigate(BuildContext context, Widget page) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      debugPrint("🔥 Nav Error: $e");
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final settings = await _messaging.requestPermission();
      debugPrint("🔔 Permission: ${settings.authorizationStatus}");

      if (!kIsWeb) {
        await FirebaseMessaging.instance.subscribeToTopic("allUsers");
      }

      await _saveToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _saveToken(token: token);
      });

      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? "إشعار";
        final body = message.notification?.body ?? "";
        debugPrint("📩 Foreground: $title");

        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (navigatorKey.currentState == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title\n$body")),
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNavigation(initialMessage);
        });
      }
    } catch (e) {
      debugPrint("🔥 Init Error: $e");
    }
  }

  static Future<void> _saveToken({String? token}) async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      token ??= await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      if (_lastSavedToken == token) return;
      _lastSavedToken = token;

      final ref = FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid);

      final doc = await ref.get();
      List tokens = doc.data()?['fcmTokens'] ?? [];

      if (tokens.contains(token)) return;

      await ref.set({
        "fcmTokens": FieldValue.arrayUnion([token]),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("🔥 Token Save Error: $e");
    }
  }

  static void _handleNavigation(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      final context = navigatorKey.currentContext;
      if (context == null) return;

      final courseId = data['courseId'];
      final lessonId = data['lessonId'];
      final title = data['title'] ?? "";

      if (courseId != null && lessonId == null) {
        safeNavigate(
          context,
          CourseDetailsPage(
            title: title,
            courseId: courseId,
          ),
        );
        return;
      }

      if (lessonId != null) {
        safeNavigate(
          context,
          VideoPage(
            title: title,
            videoUrl: data['videoUrl'] ?? "",
            courseId: courseId ?? "",
            lessonId: lessonId,
            isFree: true,
          ),
        );
        return;
      }

      debugPrint("🔔 General Notification");
    } catch (e) {
      debugPrint("🔥 Navigation Error: $e");
    }
  }

  static Future<void> saveNotification({
    required String title,
    required String body,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .add({
        "title": title,
        "body": body,
        "userId": userId,
        "data": data ?? {},
        "seen": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Firestore Notification Error: $e");
    }
  }

  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    await saveNotification(
      title: title,
      body: body,
      userId: userId,
      data: data,
    );

    if (kIsWeb) return true;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable("sendNotification");
      await callable.call({
        "title": title,
        "body": body,
        "userId": userId,
        "data": data ?? {},
      });
      debugPrint("🔥 Push Sent");
      return true;
    } catch (e) {
      debugPrint("⚠️ Push skipped (no functions)");
      return true;
    }
  }
}