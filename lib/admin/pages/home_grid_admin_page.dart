import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class HomeGridAdminPage extends StatefulWidget {
  const HomeGridAdminPage({super.key});

  @override
  State<HomeGridAdminPage> createState() => _HomeGridAdminPageState();
}

class _HomeGridAdminPageState extends State<HomeGridAdminPage> {

  List<Map<String, dynamic>> items = [];

  bool loading = true;

  final List<Map<String, dynamic>> defaultItems = [
    {"id": "courses", "title": "الكورسات"},
    {"id": "payment", "title": "الدفع"},
    {"id": "leaderboard", "title": "المتصدرين"},
    {"id": "instructor", "title": "المدرس"},
    {"id": "admin", "title": "Admin"},
    {"id": "center", "title": "السنتر"},
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("home_grid")
          .get();

      if (doc.exists && doc.data()?['items'] != null) {
        final raw = doc.data()!['items'] as List;

        items = raw.map<Map<String, dynamic>>((e) {
          return {
            "id": e['id'],
            "enabled": e['enabled'] ?? true,
          };
        }).toList();
      } else {
        items = defaultItems.map((e) {
          return {
            "id": e['id'],
            "enabled": true,
          };
        }).toList();
      }
    } catch (_) {
      items = defaultItems.map((e) {
        return {
          "id": e['id'],
          "enabled": true,
        };
      }).toList();
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> save() async {
    try {
      await FirebaseService.firestore
          .collection("app_settings")
          .doc("home_grid")
          .set({
        "items": items,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم الحفظ ✅")),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الحفظ ❌")),
      );
    }
  }

  String getTitle(String id) {
    final found = defaultItems.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {"title": id},
    );
    return found['title'];
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
        title: const Text("⚡ إدارة الوصول السريع"),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: save,
          )
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;

          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);

          setState(() {});
        },
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            key: ValueKey(item['id']),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              title: Text(
                getTitle(item['id']),
                style: const TextStyle(color: Colors.white),
              ),
              leading: const Icon(Icons.drag_handle, color: Colors.grey),
              trailing: Switch(
                value: item['enabled'] == true,
                onChanged: (val) {
                  setState(() {
                    item['enabled'] = val;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}