import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import '../../core/permission_service.dart';
import '../../core/audit_service.dart';

class PermissionsAdminPage extends StatefulWidget {
  const PermissionsAdminPage({super.key});

  @override
  State<PermissionsAdminPage> createState() => _PermissionsAdminPageState();
}

class _PermissionsAdminPageState extends State<PermissionsAdminPage> {
  bool loading = true;

  Map<String, dynamic> permissions = {};

  final pages = [
    "home",
    "courses",
    "profile",
    "attendance",
    "finance",
    "admin",
    "qr",
    "analytics",
    "students",
    "news",
    "users",
    "payments",
    "notifications",
    "categories",
    "instructor_requests",
    "students_crm",
    "admin_navigation",
    "pricing",
    "verify_certificate",
    "permissions",
  ];

  final roles = [
    "admin",
    "vip",
    "subscriber",
    "user",
    "guest",
  ];

  @override
  void initState() {
    super.initState();
    loadPermissions();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map(
        (key, value) => MapEntry(_normalize(key.toString()), value == true),
      );
    }

    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(_normalize(key.toString()), value == true),
      );
    }

    return {};
  }

  Map<String, dynamic> _normalizePermissions(dynamic value) {
    if (value is! Map) return {};
    final result = <String, dynamic>{};

    for (final entry in value.entries) {
      final roleKey = _normalize(entry.key.toString());
      result[roleKey] = _normalizeMap(entry.value);
    }

    return result;
  }

  Map<String, dynamic> _buildRolePermissions(List<String> allowedPages) {
    final allowed = allowedPages.toSet();
    return {
      for (final page in pages) page: allowed.contains(page),
    };
  }

  Map<String, dynamic> _defaultPermissions() {
    return {
      "admin": _buildRolePermissions(pages),
      "vip": _buildRolePermissions([
        "home",
        "courses",
        "profile",
        "attendance",
        "finance",
        "qr",
        "news",
        "students",
      ]),
      "subscriber": _buildRolePermissions([
        "home",
        "courses",
        "profile",
        "attendance",
        "finance",
        "news",
      ]),
      "user": _buildRolePermissions([
        "home",
        "courses",
        "profile",
        "news",
      ]),
      "guest": _buildRolePermissions([
        "home",
        "news",
        "verify_certificate",
      ]),
    };
  }

  Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic> loaded) {
    final defaults = _defaultPermissions();
    final merged = <String, dynamic>{};

    for (final entry in defaults.entries) {
      final roleKey = _normalize(entry.key.toString());
      final baseMap = _normalizeMap(entry.value);
      final loadedMap = _normalizeMap(loaded[roleKey]);

      baseMap.addAll(loadedMap);
      merged[roleKey] = baseMap;
    }

    for (final entry in loaded.entries) {
      final roleKey = _normalize(entry.key.toString());
      if (!merged.containsKey(roleKey)) {
        merged[roleKey] = _normalizeMap(entry.value);
      }
    }

    return merged;
  }

  Future<void> loadPermissions() async {
    try {
      await PermissionService.load();

      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("permissions")
          .get();

      final data = doc.data();

      if (data is Map<String, dynamic>) {
        permissions = _mergeWithDefaults(_normalizePermissions(data));
      } else {
        permissions = _defaultPermissions();
      }

      if (permissions.isEmpty) {
        permissions = _defaultPermissions();

        await FirebaseService.firestore
            .collection("app_settings")
            .doc("permissions")
            .set(permissions, SetOptions(merge: true));

        await PermissionService.save(permissions);
      }

      await PermissionService.reload();

      if (!mounted) return;
      setState(() {
        loading = false;
      });
    } catch (_) {
      if (permissions.isEmpty) {
        permissions = _defaultPermissions();
      }

      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> togglePermission(String role, String page) async {
    final roleKey = _normalize(role);
    final pageKey = _normalize(page);

    final defaultPermissions = _defaultPermissions();
    final roleMap = _normalizeMap(permissions[roleKey]);

    if (defaultPermissions[roleKey] is Map) {
      final defaultRoleMap = _normalizeMap(defaultPermissions[roleKey]);
      for (final entry in defaultRoleMap.entries) {
        roleMap.putIfAbsent(entry.key, () => entry.value);
      }
    }

    final current = roleMap[pageKey] == true;
    roleMap[pageKey] = !current;
    permissions[roleKey] = roleMap;

    if (mounted) {
      setState(() {});
    }

    try {
      await FirebaseService.firestore
          .collection("app_settings")
          .doc("permissions")
          .set({
        roleKey: roleMap,
      }, SetOptions(merge: true));

      await PermissionService.save(permissions);
      await PermissionService.reload();

      await AuditService.log(
        action: "permission_toggled",
        data: {
          "role": roleKey,
          "page": pageKey,
          "value": roleMap[pageKey],
        },
      );
    } catch (_) {}
  }

  bool hasAccess(String role, String page) {
    final roleKey = _normalize(role);
    final pageKey = _normalize(page);

    final roleMap = _normalizeMap(permissions[roleKey]);
    if (roleMap.isEmpty) return false;

    return roleMap[pageKey] == true;
  }

  Future<void> _resetToDefaults() async {
    if (!mounted) return;
    setState(() {
      loading = true;
    });

    try {
      permissions = _defaultPermissions();

      await FirebaseService.firestore
          .collection("app_settings")
          .doc("permissions")
          .set(permissions, SetOptions(merge: true));

      await PermissionService.save(permissions);
      await PermissionService.reload();

      await AuditService.log(
        action: "permissions_reset",
        data: {
          "status": "reset_to_default",
        },
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "🔐 إدارة الصلاحيات",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text(
              "إعادة ضبط",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: roles.map((role) {
          final roleMap = _normalizeMap(permissions[_normalize(role)]);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: pages.map((page) {
                    final active = roleMap[_normalize(page)] == true;

                    return GestureDetector(
                      onTap: () => togglePermission(role, page),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          page,
                          style: TextStyle(
                            color: active ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  "مفعّل: ${roleMap.values.where((e) => e == true).length} / ${pages.length}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}