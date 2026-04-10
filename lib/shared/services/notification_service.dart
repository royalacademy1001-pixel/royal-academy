import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class NotificationService {
  static bool _initialized = false;
  static String? _lastTokenSaved;

  static Future<void> init() async {
    try {
      await FirebaseInit.init();

      if (_initialized || kIsWeb) return;
      _initialized = true;

      await FirebaseService.refreshCurrentUser();
      await FirebaseService.messaging.requestPermission();

      await updateToken();

      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint("🔔 ${message.notification?.title}");
      });

      await subscribe(AppConstants.topicAllUsers);
    } catch (e) {
      debugPrint("🔥 Notification Error: $e");
    }
  }

  static Future<void> subscribe(String topic) async {
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

      final user = FirebaseService.auth.currentUser;
      if (user == null || token.isEmpty) return;

      if (_lastTokenSaved == token) return;
      _lastTokenSaved = token;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "fcmTokens": FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("🔥 Token Error: $e");
    }
  }

  static Future<void> updateToken() async {
    try {
      await FirebaseInit.init();

      if (kIsWeb) return;

      final token = await FirebaseService.messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint("🔥 Update Token Error: $e");
    }
  }
}