import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class AuthService {
  static Map<String, dynamic>? _userCache;
  static DateTime? _lastFetchTime;

  static bool _fetchingUser = false;
  static Completer<Map<String, dynamic>>? _userCompleter;

  static const int _cacheSeconds = AppConstants.cacheSeconds;

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

      await FirebaseService.refreshCurrentUser();

      final user = FirebaseService.auth.currentUser;

      if (user == null) {
        _completeUser({});
        return {};
      }

      final doc = await safeTimeout(() =>
          safeFirestoreCall(() =>
              FirebaseService.firestore
                  .collection(AppConstants.users)
                  .doc(user.uid)
                  .get()));

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

  static Future<void> logout() async {
    try {
      await FirebaseInit.init();

      final user = FirebaseService.auth.currentUser;

      if (!kIsWeb) {
        await FirebaseService.messaging.deleteToken();
      }

      if (user != null) {
        await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(user.uid)
            .set({
          "fcmTokens": [],
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }

    clearUserCache();
    await FirebaseService.auth.signOut();
  }

  static Future<void> refreshUser() async {
    await FirebaseService.refreshCurrentUser();
    clearUserCache();
  }

  static void clearUserCache() {
    _userCache = null;
    _lastFetchTime = null;
  }

  static void _completeUser(Map<String, dynamic> data) {
    _fetchingUser = false;

    if (_userCompleter != null &&
        !_userCompleter!.isCompleted) {
      _userCompleter!.complete(data);
    }
  }
}