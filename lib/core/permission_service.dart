import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class PermissionService {
  static Map<String, dynamic> _permissions = {};
  static bool _loaded = false;

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  static bool _isListening = false;

  static const Set<String> _metaKeys = {
    'updatedat',
    'createdat',
    'createdby',
    'lastupdatedat',
    'version',
    'name',
    'title',
    'description',
    'status',
    'enabled',
    'active',
  };

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = _normalize(value);
      return v == 'true' || v == '1' || v == 'yes' || v == 'on';
    }
    return false;
  }

  static Map<String, dynamic> _normalizeMap(dynamic value) {
    final result = <String, dynamic>{};

    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        final key = _normalize(entry.key.toString());
        if (key.isEmpty) continue;
        result[key] = _asBool(entry.value);
      }
      return result;
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final key = _normalize(entry.key.toString());
        if (key.isEmpty) continue;
        result[key] = _asBool(entry.value);
      }
      return result;
    }

    if (value is List) {
      for (final item in value) {
        final key = _normalize(item.toString());
        if (key.isNotEmpty) {
          result[key] = true;
        }
      }
      return result;
    }

    if (value is String) {
      final key = _normalize(value);
      if (key.isNotEmpty) {
        result[key] = true;
      }
    }

    return result;
  }

  static Map<String, dynamic> _normalizePermissions(dynamic value) {
    if (value is! Map) return {};

    final source = value['permissions'] is Map
        ? value['permissions']
        : value['roles'] is Map
            ? value['roles']
            : value;

    if (source is! Map) return {};

    final result = <String, dynamic>{};

    for (final entry in source.entries) {
      final roleKey = _normalize(entry.key.toString());
      if (roleKey.isEmpty) continue;
      if (_metaKeys.contains(roleKey)) continue;

      final normalized = _normalizeMap(entry.value);
      if (normalized.isNotEmpty) {
        result[roleKey] = normalized;
      }
    }

    return result;
  }

  static Future<void> load({bool forceReload = false}) async {
    if (_loaded && !forceReload && _isListening) return;

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
        }, onError: (_) {
          _permissions = {};
          _loaded = false;
          _isListening = false;
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
    if (userData == null) return "user";

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

  static Map<String, dynamic>? _resolveRoleData(String roleKey) {
    final direct = _permissions[roleKey];
    if (direct != null) {
      final normalized = _normalizeMap(direct);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    final fallback = _permissions['default'] ?? _permissions['all'];
    if (fallback != null) {
      final normalized = _normalizeMap(fallback);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  static bool canAccess({
    required String role,
    required String page,
  }) {
    final roleKey = _normalize(role);
    final pageKey = _normalize(page);

    if (pageKey == "home" || pageKey == "profile") return true;
    if (pageKey == "courses" || pageKey == "payment") return true;
    if (roleKey == "admin") return true;
    if (!_loaded) return true;
    if (_permissions.isEmpty) return true;

    final roleData = _resolveRoleData(roleKey);
    if (roleData == null || roleData.isEmpty) return true;

    if (!roleData.containsKey(pageKey)) return true;

    return roleData[pageKey] == true;
  }

  static bool canAccessQuickAccess({
    required String role,
    required List<dynamic>? roles,
  }) {
    if (roles == null || roles.isEmpty) return true;

    final roleKey = _normalize(role);

    final normalizedRoles =
        roles.map((e) => _normalize(e.toString())).toList();

    return normalizedRoles.contains(roleKey) || normalizedRoles.contains("all");
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