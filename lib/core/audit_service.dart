import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AuditService {
  static Future<void> log({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = FirebaseService.auth.currentUser;

      await FirebaseService.firestore.collection("audit_logs").add({
        "userId": user?.uid ?? "guest",
        "email": user?.email ?? "",
        "action": action,
        "data": data ?? {},
        "timestamp": FieldValue.serverTimestamp(),
        "clientTime": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Audit Error: $e");
    }
  }
}