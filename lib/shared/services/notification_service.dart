import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class NotificationService {
  static bool _initialized = false;
  static String? _lastTokenSaved;
  static DateTime? _lastTokenTime;
  static bool _saving = false;

  static Future<void> init() async {
    try {
      await FirebaseInit.init();

      if (_initialized || kIsWeb) return;
      _initialized = true;

      await FirebaseService.refreshCurrentUser();
      await FirebaseService.messaging.requestPermission();

      await updateToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (token.isNotEmpty) {
          _saveToken(token);
        }
      });

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

      if (!kIsWeb && topic.trim().isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic(topic.trim());
      }
    } catch (e) {
      debugPrint("🔥 Topic Subscribe Error: $e");
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      await FirebaseInit.init();

      if (token.isEmpty) return;

      final now = DateTime.now();

      if (_saving) return;

      final lastTime = _lastTokenTime;
      if (_lastTokenSaved == token &&
          lastTime != null &&
          now.difference(lastTime).inSeconds < 30) {
        return;
      }

      _saving = true;

      final user = FirebaseService.auth.currentUser;
      if (user == null || user.uid.isEmpty) {
        _saving = false;
        return;
      }

      _lastTokenSaved = token;
      _lastTokenTime = now;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "fcmTokens": FieldValue.arrayUnion([token]),
        "lastTokenUpdate": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("🔥 Token Error: $e");
    } finally {
      _saving = false;
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