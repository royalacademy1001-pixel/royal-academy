import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/firebase_service.dart';
import '../../core/colors.dart';
import '../../core/permission_service.dart';
import '../../core/audit_service.dart';

class AdminNavigationControlPage extends StatefulWidget {
  const AdminNavigationControlPage({super.key});

  @override
  State<AdminNavigationControlPage> createState() =>
      _AdminNavigationControlPageState();
}

class _AdminNavigationControlPageState
    extends State<AdminNavigationControlPage> {
  final List<Map<String, dynamic>> items = [];

  bool loading = true;
  bool saving = false;

  final titleController = TextEditingController();
  final idController = TextEditingController();
  final iconController = TextEditingController();

  int order = 1;

  Set<String> roles = {"all"};

  String selectedPageId = "home";

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _navSub;

  final List<Map<String, dynamic>> availablePages = [
    {
      "id": "home",
      "title": "الرئيسية",
      "icon": "home",
      "roles": ["all"],
    },
    {
      "id": "dashboard",
      "title": "لوحة التحكم",
      "icon": "dashboard",
      "roles": ["admin"],
    },
    {
      "id": "center_management",
      "title": "إدارة السنتر",
      "icon": "building",
      "roles": ["admin"],
    },
    {
      "id": "attendance_take",
      "title": "تسجيل الحضور",
      "icon": "attendance",
      "roles": ["admin", "instructor"],
    },
    {
      "id": "attendance_report",
      "title": "تقارير الحضور",
      "icon": "report",
      "roles": ["admin", "instructor"],
    },
    {
      "id": "attendance_sessions",
      "title": "جلسات الحضور",
      "icon": "calendar",
      "roles": ["admin", "instructor"],
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "roles": ["all"],
    },
    {
      "id": "courses_admin",
      "title": "إدارة الكورسات",
      "icon": "courses",
      "roles": ["admin"],
    },
    {
      "id": "subjects",
      "title": "إدارة المواد",
      "icon": "book",
      "roles": ["admin"],
    },
    {
      "id": "subject_sessions",
      "title": "حصص المادة",
      "icon": "calendar",
      "roles": ["admin", "instructor"],
    },
    {
      "id": "students_management",
      "title": "إدارة الطلاب",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "edit_student",
      "title": "تعديل طالب",
      "icon": "edit",
      "roles": ["admin"],
    },
    {
      "id": "students_crm",
      "title": "CRM الطلاب",
      "icon": "analytics",
      "roles": ["admin"],
    },
    {
      "id": "student_financial",
      "title": "مصاريف الطالب",
      "icon": "wallet",
      "roles": ["admin"],
    },
    {
      "id": "finance_reports",
      "title": "تقارير مالية",
      "icon": "money",
      "roles": ["admin"],
    },
    {
      "id": "top_students",
      "title": "أفضل الطلاب",
      "icon": "trophy",
      "roles": ["admin"],
    },
    {
      "id": "comments",
      "title": "التعليقات",
      "icon": "chat",
      "roles": ["admin"],
    },
    {
      "id": "analytics_dashboard",
      "title": "تحليلات",
      "icon": "analytics",
      "roles": ["admin"],
    },
    {
      "id": "instructor_requests_admin",
      "title": "طلبات المدرسين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "notifications",
      "title": "الإشعارات",
      "icon": "notifications",
      "roles": ["admin"],
    },
    {
      "id": "news",
      "title": "الأخبار",
      "icon": "news",
      "roles": ["admin"],
    },
    {
      "id": "users",
      "title": "المستخدمين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "verify_certificate",
      "title": "التحقق من الشهادة",
      "icon": "verify",
      "roles": ["admin", "all"],
    },
    {
      "id": "admin_payments",
      "title": "المدفوعات",
      "icon": "payment",
      "roles": ["admin"],
    },
    {
      "id": "admin_requests",
      "title": "طلبات المدرسين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "admin_analytics",
      "title": "Analytics",
      "icon": "analytics",
      "roles": ["admin"],
    },
    {
      "id": "admin_users",
      "title": "المستخدمين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "admin_nav_control",
      "title": "التحكم في البار",
      "icon": "settings",
      "roles": ["admin"],
    },
    {
      "id": "admin_permissions",
      "title": "الصلاحيات",
      "icon": "settings",
      "roles": ["admin"],
    },
    {
      "id": "admin_categories",
      "title": "إدارة التصنيفات",
      "icon": "categories",
      "roles": ["admin"],
    },
    {
      "id": "admin_notifications",
      "title": "إدارة الإشعارات",
      "icon": "notifications",
      "roles": ["admin"],
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "roles": ["all"],
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "roles": ["all"],
    },
    {
      "id": "instructor",
      "title": "لوحة المدرس",
      "icon": "instructor",
      "roles": ["instructor"],
    },
  ];

  final List<Map<String, dynamic>> fallbackNav = [
    {
      "id": "home",
      "title": "الرئيسية",
      "icon": "home",
      "order": 1,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "order": 2,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "order": 3,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "order": 4,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "dashboard",
      "title": "لوحة التحكم",
      "icon": "dashboard",
      "order": 5,
      "roles": ["admin"],
      "enabled": true,
    },
    {
      "id": "center_management",
      "title": "إدارة السنتر",
      "icon": "building",
      "order": 6,
      "roles": ["admin"],
      "enabled": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _navSub?.cancel();
    titleController.dispose();
    idController.dispose();
    iconController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _cloneItems(List<Map<String, dynamic>> source) {
    return source.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic raw) {
    if (raw is! List) return [];

    final normalized = <Map<String, dynamic>>[];

    for (final entry in raw) {
      if (entry is! Map) continue;

      final item = Map<String, dynamic>.from(entry);
      item["id"] = (item["id"] ?? "").toString().trim().toLowerCase();
      item["title"] = (item["title"] ?? "").toString().trim();
      item["icon"] = (item["icon"] ?? "settings").toString().trim();
      item["order"] = item["order"] is int
          ? item["order"]
          : int.tryParse(item["order"]?.toString() ?? "") ?? 0;
      item["enabled"] = item["enabled"] != false;

      final rawRoles = item["roles"];
      if (rawRoles is List) {
        item["roles"] =
            rawRoles.map((e) => e.toString().toLowerCase()).toList();
      } else {
        item["roles"] = ["all"];
      }

      normalized.add(item);
    }

    normalized.sort((a, b) {
      final aOrder = a["order"] is int
          ? a["order"] as int
          : int.tryParse(a["order"]?.toString() ?? "") ?? 0;
      final bOrder = b["order"] is int
          ? b["order"] as int
          : int.tryParse(b["order"]?.toString() ?? "") ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return normalized;
  }

  List<String> _normalizeRoles(dynamic raw) {
    if (raw is List) {
      final rolesList = raw
          .map((e) => e.toString().toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (rolesList.isEmpty) return ["all"];
      return rolesList.toList();
    }
    return ["all"];
  }

  Map<String, dynamic> _templateFor(String pageId) {
    return availablePages.firstWhere(
      (e) => e["id"] == pageId,
      orElse: () => {
        "id": pageId,
        "title": pageId,
        "icon": "settings",
        "roles": ["all"],
      },
    );
  }

  int _indexOfItem(String pageId) {
    return items.indexWhere((e) => (e["id"] ?? "").toString() == pageId);
  }

  void _applyTemplate(String pageId) {
    selectedPageId = pageId;

    final template = _templateFor(pageId);
    final index = _indexOfItem(pageId);

    if (index != -1) {
      final item = items[index];
      idController.text = (item["id"] ?? template["id"]).toString();
      titleController.text = (item["title"] ?? template["title"]).toString();
      iconController.text = (item["icon"] ?? template["icon"]).toString();
      order = item["order"] is int
          ? item["order"] as int
          : int.tryParse(item["order"]?.toString() ?? "") ?? items.length + 1;
      roles = _normalizeRoles(item["roles"] ?? template["roles"]).toSet();
    } else {
      idController.text = template["id"].toString();
      titleController.text = template["title"].toString();
      iconController.text = template["icon"].toString();
      order = items.length + 1;
      roles = _normalizeRoles(template["roles"]).toSet();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _bootstrap() async {
    await PermissionService.load();
    final navRef =
        FirebaseService.firestore.collection("app_settings").doc("navigation");

    try {
      final doc = await navRef.get();
      if (!mounted) return;

      final data = doc.data();
      final rawItems = data?["items"];

      if (rawItems == null || rawItems is! List || rawItems.isEmpty) {
        items
          ..clear()
          ..addAll(_cloneItems(fallbackNav));

        await navRef.set({
          "items": _cloneItems(fallbackNav),
        }, SetOptions(merge: true));
      } else {
        items
          ..clear()
          ..addAll(_normalizeItems(rawItems));
      }

      _applyTemplate(selectedPageId);

      _navSub = navRef.snapshots().listen(
        (snapshot) {
          if (!mounted) return;

          final liveData = snapshot.data();
          final liveItems = liveData?["items"];

          final nextItems =
              (liveItems == null || liveItems is! List || liveItems.isEmpty)
                  ? _cloneItems(fallbackNav)
                  : _normalizeItems(liveItems);

          setState(() {
            items
              ..clear()
              ..addAll(nextItems);
          });

          _applyTemplate(selectedPageId);
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            items
              ..clear()
              ..addAll(_cloneItems(fallbackNav));
          });
          _applyTemplate(selectedPageId);
        },
      );

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        items
          ..clear()
          ..addAll(_cloneItems(fallbackNav));
        loading = false;
      });
      _applyTemplate(selectedPageId);
    }
  }

  void addItem() {
    final pageId = idController.text.trim().toLowerCase();
    final title = titleController.text.trim();
    final icon = iconController.text.trim();

    if (pageId.isEmpty || title.isEmpty) return;

    final newItem = {
      "id": pageId,
      "title": title,
      "icon": icon.isEmpty ? "settings" : icon,
      "order": order,
      "roles": roles.map((e) => e.toLowerCase()).toList(),
      "enabled": true,
    };

    final index = items.indexWhere((e) => (e["id"] ?? "").toString() == pageId);

    if (index != -1) {
      items[index] = newItem;
    } else {
      items.add(newItem);
    }

    saveAll();

    AuditService.log(
      action: "nav_add_or_update",
      data: newItem,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void clearForm() {
    titleController.clear();
    idController.clear();
    iconController.clear();
    order = items.length + 1;
    roles = {"all"};
    selectedPageId = "home";
    if (mounted) {
      setState(() {});
    }
  }

  void deleteItem(int index) {
    if (index < 0 || index >= items.length) return;
    final item = items[index];

    items.removeAt(index);
    saveAll();

    AuditService.log(
      action: "nav_delete",
      data: item,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void toggleRole(String role) {
    final r = role.toLowerCase();
    if (roles.contains(r)) {
      roles.remove(r);
    } else {
      roles.add(r);
    }

    if (roles.isEmpty) {
      roles = {"all"};
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveAll() async {
    if (saving) return;

    if (!mounted) return;
    setState(() => saving = true);

    try {
      await FirebaseService.firestore
          .collection("app_settings")
          .doc("navigation")
          .set({
        "items": items,
      }, SetOptions(merge: true));

      await AuditService.log(
        action: "nav_save",
        data: {"count": items.length},
      );
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void updateOrder(int index, int newOrder) {
    if (index < 0 || index >= items.length) return;
    items[index]["order"] = newOrder <= 0 ? 1 : newOrder;
    items.sort((a, b) {
      final aOrder = a["order"] is int
          ? a["order"] as int
          : int.tryParse(a["order"].toString()) ?? 0;
      final bOrder = b["order"] is int
          ? b["order"] as int
          : int.tryParse(b["order"].toString()) ?? 0;
      return aOrder.compareTo(bOrder);
    });
    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  void updateField(int index, String key, dynamic value) {
    if (index < 0 || index >= items.length) return;
    if (key == "roles" && value is List) {
      items[index][key] = value.map((e) => e.toString().toLowerCase()).toList();
    } else if (key == "id") {
      items[index][key] = value.toString().toLowerCase();
    } else {
      items[index][key] = value;
    }
    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  void toggleEnabled(int index) {
    if (index < 0 || index >= items.length) return;
    items[index]["enabled"] = !(items[index]["enabled"] ?? true);
    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex >= items.length) {
      return;
    }

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    for (int i = 0; i < items.length; i++) {
      items[i]["order"] = i + 1;
    }

    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  Widget _iconPreview(String icon) {
    return Icon(
      _iconFromName(icon),
      color: AppColors.gold,
      size: 18,
    );
  }

  IconData _iconFromName(String name) {
    switch (name.toLowerCase()) {
      case "home":
        return Icons.home;
      case "dashboard":
        return Icons.dashboard;
      case "building":
      case "center":
      case "management":
        return Icons.apartment;
      case "attendance":
        return Icons.fact_check;
      case "report":
        return Icons.assignment;
      case "calendar":
        return Icons.calendar_month;
      case "courses":
        return Icons.school;
      case "book":
        return Icons.book;
      case "users":
        return Icons.group;
      case "edit":
        return Icons.edit;
      case "wallet":
        return Icons.account_balance_wallet;
      case "money":
      case "payment":
        return Icons.payments;
      case "trophy":
        return Icons.emoji_events;
      case "chat":
        return Icons.chat_bubble_outline;
      case "analytics":
        return Icons.analytics;
      case "notifications":
        return Icons.notifications;
      case "news":
        return Icons.newspaper;
      case "verify":
        return Icons.verified;
      case "settings":
        return Icons.settings;
      case "profile":
        return Icons.person;
      case "categories":
        return Icons.category;
      default:
        return Icons.widgets;
    }
  }

  Widget _pageSelector() {
    final hasSelected =
        availablePages.any((page) => page["id"].toString() == selectedPageId);

    return DropdownButtonFormField<String>(
      initialValue: hasSelected ? selectedPageId : null,
      dropdownColor: AppColors.black,
      decoration: InputDecoration(
        labelText: "اختار الصفحة",
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      items: availablePages.map((page) {
        final id = page["id"].toString();
        final title = page["title"].toString();
        final icon = page["icon"].toString();

        return DropdownMenuItem<String>(
          value: id,
          child: Row(
            children: [
              _iconPreview(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        _applyTemplate(value);
      },
    );
  }

  void _moveUp(int index) {
    if (index <= 0 || index >= items.length) return;

    final temp = items[index - 1];
    items[index - 1] = items[index];
    items[index] = temp;

    for (int i = 0; i < items.length; i++) {
      items[i]["order"] = i + 1;
    }

    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  void _moveDown(int index) {
    if (index < 0 || index >= items.length - 1) return;

    final temp = items[index + 1];
    items[index + 1] = items[index];
    items[index] = temp;

    for (int i = 0; i < items.length; i++) {
      items[i]["order"] = i + 1;
    }

    saveAll();

    if (mounted) {
      setState(() {});
    }
  }

  Widget roleChip(String role) {
    final r = role.toLowerCase();
    final selected = roles.contains(r);

    return GestureDetector(
      onTap: () => toggleRole(r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.gold : Colors.white10),
        ),
        child: Text(
          role,
          style: TextStyle(color: selected ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    final isHome = (item["id"] ?? "").toString() == "home";
    final enabled = item["enabled"] ?? true;
    final iconName = (item["icon"] ?? "settings").toString();
    final title = (item["title"] ?? "").toString();
    final itemId = (item["id"] ?? "").toString();
    final itemOrder = item["order"]?.toString() ?? "0";
    final itemRoles = item["roles"] is List
        ? (item["roles"] as List)
            .map((e) => e.toString().toLowerCase())
            .toList()
        : <String>[];

    return Container(
      key: ValueKey("${itemId}_$index"),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _iconPreview(iconName),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.isEmpty ? itemId : title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isHome)
                Switch(
                  value: enabled == true,
                  onChanged: (_) => toggleEnabled(index),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.lock, color: Colors.green),
                ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_handle,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: title,
            onChanged: (v) => updateField(index, "title", v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "title",
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: iconName,
            onChanged: (v) => updateField(index, "icon", v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "icon name",
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: itemOrder,
            keyboardType: TextInputType.number,
            onChanged: (v) => updateOrder(index, int.tryParse(v) ?? 0),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "order",
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: ["all", "admin", "instructor", "vip", "user"]
                .map(
                  (r) => FilterChip(
                    label: Text(r),
                    selected: itemRoles.contains(r),
                    onSelected: (_) {
                      final updatedRoles = List<String>.from(itemRoles);

                      if (updatedRoles.contains(r)) {
                        updatedRoles.remove(r);
                      } else {
                        updatedRoles.add(r);
                      }

                      if (updatedRoles.isEmpty) {
                        updatedRoles.add("all");
                      }

                      updateField(index, "roles", updatedRoles);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                onPressed: () => _moveUp(index),
              ),
              IconButton(
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () => _moveDown(index),
              ),
              if (!isHome)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteItem(index),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "⚙️ التحكم في الناف بار",
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
          : items.isEmpty
              ? const Center(child: Text("No Data"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _pageSelector(),
                            const SizedBox(height: 10),
                            TextField(
                              controller: idController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "id (home, courses...)",
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (v) {
                                final trimmed = v.trim().toLowerCase();
                                final found = availablePages
                                    .where((e) =>
                                        e["id"].toString().toLowerCase() ==
                                        trimmed)
                                    .toList();
                                if (found.isNotEmpty &&
                                    titleController.text.isEmpty) {
                                  titleController.text =
                                      found.first["title"].toString();
                                  iconController.text =
                                      found.first["icon"].toString();
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "title",
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: iconController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "icon name",
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                roleChip("all"),
                                roleChip("admin"),
                                roleChip("instructor"),
                                roleChip("vip"),
                                roleChip("user"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: addItem,
                              child: const Text("➕ إضافة"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: reorder,
                        children: items.asMap().entries.map((entry) {
                          return _buildItemCard(entry.key, entry.value);
                        }).toList(),
                      )
                    ],
                  ),
                ),
    );
  }
}
