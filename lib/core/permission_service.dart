import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class PermissionService {
  static Map<String, dynamic> _permissions = {};
  static bool _loaded = false;

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  static bool _isListening = false;

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, value) => MapEntry(_normalize(key.toString()), value == true),
      );
    }

    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(_normalize(key.toString()), value == true),
      );
    }

    return {};
  }

  static Map<String, dynamic> _normalizePermissions(dynamic value) {
    if (value is! Map) return {};

    final result = <String, dynamic>{};

    for (final entry in value.entries) {
      final roleKey = _normalize(entry.key.toString());
      result[roleKey] = _normalizeMap(entry.value);
    }

    return result;
  }

  static Future<void> load({bool forceReload = false}) async {
    if (_loaded && !forceReload) return;

    try {
      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("permissions")
          .get();

      final data = doc.data();

      if (data is Map<String, dynamic>) {
        _permissions = _normalizePermissions(data);
      } else {
        _permissions = {};
      }

      if (!_isListening) {
        await _sub?.cancel();
        _sub = FirebaseService.firestore
            .collection("app_settings")
            .doc("permissions")
            .snapshots()
            .listen((snapshot) {
          final data = snapshot.data();
          if (data is Map<String, dynamic>) {
            _permissions = _normalizePermissions(data);
          } else {
            _permissions = {};
          }
        });
        _isListening = true;
      }

      _loaded = true;
    } catch (_) {
      _permissions = {};
      _loaded = false;
      _isListening = false;
      await _sub?.cancel();
      _sub = null;
    }
  }

  static Future<void> reload() async {
    _loaded = false;
    _isListening = false;
    await _sub?.cancel();
    _sub = null;
    await load(forceReload: true);
  }

  static Future<void> save(Map<String, dynamic> permissions) async {
    _permissions = _normalizePermissions(permissions);
    _loaded = true;

    await FirebaseService.firestore
        .collection("app_settings")
        .doc("permissions")
        .set(_permissions, SetOptions(merge: true));
  }

  static String getRole(Map<String, dynamic>? userData) {
    if (userData == null) return "guest";

    if (userData['isAdmin'] == true) return "admin";
    if (userData['isVIP'] == true) return "vip";
    if (userData['instructorApproved'] == true) return "instructor";

    final rawRole = userData['role']?.toString();
    final role = rawRole == null ? "" : _normalize(rawRole);

    if (role.isNotEmpty) {
      return role;
    }

    final accountType = userData['accountType']?.toString();
    if (accountType != null && _normalize(accountType).isNotEmpty) {
      return _normalize(accountType);
    }

    final subscriptionStatus = userData['subscriptionStatus']?.toString();
    if (subscriptionStatus != null &&
        _normalize(subscriptionStatus) == "active") {
      return "subscriber";
    }

    if (userData['subscribed'] == true) {
      return "subscriber";
    }

    return "user";
  }

  static bool canAccess({
    required String role,
    required String page,
  }) {
    final roleKey = _normalize(role);
    final pageKey = _normalize(page);

    if (roleKey == "admin") return true;
    if (!_loaded) return false;
    if (_permissions.isEmpty) return false;

    final roleData = _permissions[roleKey];
    if (roleData == null) return false;

    final roleMap = _normalizeMap(roleData);
    if (roleMap.isEmpty) return false;

    if (!roleMap.containsKey(pageKey)) return false;

    return roleMap[pageKey] == true;
  }

  static Map<String, dynamic> get permissions {
    return Map<String, dynamic>.unmodifiable(_permissions);
  }

  static bool get isLoaded => _loaded;

  static void clearCache() {
    _permissions = {};
    _loaded = false;
    _isListening = false;
    _sub?.cancel();
    _sub = null;
  }
}