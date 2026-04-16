import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class AdminHomeLayoutPage extends StatefulWidget {
  const AdminHomeLayoutPage({super.key});

  @override
  State<AdminHomeLayoutPage> createState() => _AdminHomeLayoutPageState();
}

class _AdminHomeLayoutPageState extends State<AdminHomeLayoutPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  bool saving = false;

  final List<Map<String, dynamic>> defaultItems = [
    {"id": "hero", "title": "الهيرو", "enabled": true},
    {"id": "vip", "title": "VIP", "enabled": true},
    {"id": "stats", "title": "الإحصائيات", "enabled": true},
    {"id": "grid", "title": "الوصول السريع", "enabled": true},
    {"id": "admin", "title": "لوحة الإدارة", "enabled": true},
    {"id": "news", "title": "الأخبار", "enabled": true},
    {"id": "continue", "title": "أكمل المشاهدة", "enabled": true},
    {"id": "recommended", "title": "مقترح لك", "enabled": true},
    {"id": "courses", "title": "الكورسات", "enabled": true},
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  List<Map<String, dynamic>> _sanitize(List<dynamic> raw) {
    final List<Map<String, dynamic>> safe = [];

    for (final e in raw) {
      if (e is Map) {
        final id = (e['id'] ?? "").toString();
        if (id.isEmpty) continue;

        safe.add({
          "id": id,
          "title": (e['title'] ?? "").toString(),
          "enabled": e['enabled'] == true,
        });
      }
    }

    if (safe.isEmpty) {
      return List<Map<String, dynamic>>.from(defaultItems);
    }

    return safe;
  }

  List<Map<String, dynamic>> _mergeWithDefaults(List<Map<String, dynamic>> current) {
    final Map<String, Map<String, dynamic>> map = {};

    for (final d in defaultItems) {
      map[d['id']] = Map<String, dynamic>.from(d);
    }

    for (final c in current) {
      final id = (c['id'] ?? "").toString();
      if (id.isEmpty) continue;

      map[id] = {
        "id": id,
        "title": (c['title'] ?? map[id]?['title'] ?? "").toString(),
        "enabled": c['enabled'] == true,
      };
    }

    return map.values.toList();
  }

  Future<void> load() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("home_layout")
          .get();

      final data = doc.data();

      if (data != null && data['items'] is List) {
        final sanitized = _sanitize(data['items']);
        items = _mergeWithDefaults(sanitized);
      } else {
        items = List<Map<String, dynamic>>.from(defaultItems);
      }
    } catch (_) {
      items = List<Map<String, dynamic>>.from(defaultItems);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (saving) return;

    saving = true;

    try {
      final List<Map<String, dynamic>> safeItems = [];

      for (int i = 0; i < items.length; i++) {
        final e = items[i];

        safeItems.add({
          "id": (e['id'] ?? "").toString(),
          "title": (e['title'] ?? "").toString(),
          "enabled": e['enabled'] == true,
          "order": i,
        });
      }

      await FirebaseService.firestore
          .collection("app_settings")
          .doc("home_layout")
          .set({
        "items": safeItems,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم الحفظ ✅")),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطأ ❌")),
      );
    } finally {
      saving = false;
    }
  }

  void toggle(int index) {
    if (index < 0 || index >= items.length) return;

    final current = items[index]['enabled'] == true;
    items[index]['enabled'] = !current;

    if (mounted) {
      setState(() {});
    }
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
        title: const Text("📐 ترتيب الصفحة الرئيسية"),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: saving ? null : save,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                "لا يوجد عناصر",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < 0 || oldIndex >= items.length) return;

                if (newIndex > oldIndex) newIndex--;

                if (newIndex < 0 || newIndex > items.length) return;

                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);

                if (mounted) {
                  setState(() {});
                }
              },
              itemBuilder: (context, index) {
                final item = items[index];

                final title = (item['title'] ?? "").toString();
                final enabled = item['enabled'] == true;

                return Container(
                  key: ValueKey(item['id'] ?? index),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle, color: Colors.white),
                    title: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Switch(
                      value: enabled,
                      activeColor: AppColors.gold,
                      onChanged: (_) => toggle(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}