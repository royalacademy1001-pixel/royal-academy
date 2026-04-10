import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase_service.dart';

class AdminNavSyncService {
  static Future<void> sync(List<Map<String, dynamic>> allAdminPages) async {
    try {
      final ref = FirebaseService.firestore
          .collection("app_settings")
          .doc("navigation");

      final doc = await ref.get();
      final data = doc.data();

      final List<Map<String, dynamic>> items = [];

      if (data != null && data['items'] is List) {
        for (final item in data['items']) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item));
          }
        }
      }

      for (final page in allAdminPages) {
        final id = (page['id'] ?? "").toString().trim();
        if (id.isEmpty) continue;

        final exists = items.any(
          (e) => (e['id'] ?? "").toString().trim() == id,
        );

        if (!exists) {
          items.add({
            "id": id,
            "title": (page['title'] ?? "").toString(),
            "icon": (page['icon'] ?? "").toString(),
            "order": items.length + 1,
            "roles": ["admin"],
            "enabled": false,
          });
        }
      }

      await ref.set({"items": items}, SetOptions(merge: true));
    } catch (_) {}
  }
}