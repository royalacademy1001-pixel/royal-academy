import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase_service.dart';
import '../../core/colors.dart';
import '../../core/permission_service.dart';

class PermissionsAdminPage extends StatefulWidget {
  const PermissionsAdminPage({super.key});

  @override
  State<PermissionsAdminPage> createState() => _PermissionsAdminPageState();
}

class _PermissionsAdminPageState extends State<PermissionsAdminPage> {
  Map<String, dynamic> permissions = {};
  bool loading = true;
  bool saving = false;

  final List<String> roles = [
    "admin",
    "instructor",
    "vip",
    "user"
  ];

  final List<String> pages = [
    "home",
    "courses",
    "attendance",
    "finance",
    "students",
    "students_crm",
    "analytics",
    "notifications",
    "news",
    "users",
    "categories",
    "payments",
    "instructor_requests",
    "admin_navigation",
    "verify_certificate"
  ];

  @override
  void initState() {
    super.initState();
    loadPermissions();
  }

  Future<void> loadPermissions() async {
    try {
      await PermissionService.load(forceReload: true);
      permissions = Map<String, dynamic>.from(PermissionService.permissions);
    } catch (_) {
      permissions = {};
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  bool isAllowed(String role, String page) {
    final roleMap = permissions[role];

    if (roleMap == null) return true;

    return roleMap[page] != false;
  }

  void togglePermission(String role, String page) {
    permissions.putIfAbsent(role, () => {});

    final roleMap = Map<String, dynamic>.from(permissions[role]);

    final current = roleMap[page] != false;

    roleMap[page] = !current;

    permissions[role] = roleMap;

    setState(() {});
  }

  Future<void> save() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      await PermissionService.save(permissions);
      await PermissionService.reload();
    } catch (_) {}

    if (mounted) {
      setState(() => saving = false);
    }
  }

  Widget buildCell(String role, String page) {
    final allowed = isAllowed(role, page);

    return GestureDetector(
      onTap: () => togglePermission(role, page),
      child: Container(
        margin: const EdgeInsets.all(4),
        height: 40,
        decoration: BoxDecoration(
          color: allowed ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          allowed ? Icons.check : Icons.close,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "🔐 إدارة الصلاحيات",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              ),
            )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 120),
                      ...roles.map((r) => Container(
                            width: 80,
                            alignment: Alignment.center,
                            child: Text(
                              r,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                    ],
                  ),
                  ...pages.map((page) {
                    return Row(
                      children: [
                        Container(
                          width: 120,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            page,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        ...roles.map((role) => SizedBox(
                              width: 80,
                              child: buildCell(role, page),
                            ))
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: save,
                    child: const Text("💾 حفظ"),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}