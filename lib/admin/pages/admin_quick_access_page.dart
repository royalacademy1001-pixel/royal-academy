import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class AdminQuickAccessPage extends StatefulWidget {
  const AdminQuickAccessPage({super.key});

  @override
  State<AdminQuickAccessPage> createState() => _AdminQuickAccessPageState();
}

class _AdminQuickAccessPageState extends State<AdminQuickAccessPage> {

  List<Map<String, dynamic>> items = [];
  bool loading = true;

  final List<String> allIds = [
    "courses",
    "payment",
    "leaderboard",
    "instructor",
    "admin",
    "center",
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

      final data = doc.data();

      if (data != null && data['items'] is List) {
        items = List<Map<String, dynamic>>.from(data['items']);
      } else {
        items = allIds.map((e) => {
          "id": e,
          "enabled": true,
          "roles": ["admin", "instructor", "student"],
        }).toList();
      }

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> save() async {
    await FirebaseService.firestore
        .collection("app_settings")
        .doc("home_grid")
        .set({
      "items": items,
    }, SetOptions(merge: true));
  }

  void toggleEnabled(int index) {
    items[index]['enabled'] = !(items[index]['enabled'] ?? true);
    setState(() {});
    save();
  }

  void toggleRole(int index, String role) {
    List roles = items[index]['roles'] ?? [];

    if (roles.contains(role)) {
      roles.remove(role);
    } else {
      roles.add(role);
    }

    items[index]['roles'] = roles;
    setState(() {});
    save();
  }

  String getTitle(String id) {
    switch (id) {
      case "courses":
        return "الكورسات";
      case "payment":
        return "الدفع";
      case "leaderboard":
        return "المتصدرين";
      case "instructor":
        return "المدرس";
      case "admin":
        return "Admin";
      case "center":
        return "السنتر";
      default:
        return id;
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
        title: const Text("⚡ إدارة الوصول السريع"),
        backgroundColor: AppColors.black,
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;

          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);

          setState(() {});
          await save();
        },
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            key: ValueKey(item['id']),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                getTitle(item['id']),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Row(
                children: [
                  _roleChip(index, "admin"),
                  const SizedBox(width: 6),
                  _roleChip(index, "instructor"),
                  const SizedBox(width: 6),
                  _roleChip(index, "student"),
                ],
              ),
              trailing: Switch(
                value: item['enabled'] ?? true,
                onChanged: (_) => toggleEnabled(index),
                activeColor: AppColors.gold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roleChip(int index, String role) {
    final roles = items[index]['roles'] ?? [];

    final active = roles.contains(role);

    return GestureDetector(
      onTap: () => toggleRole(index, role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          role,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}