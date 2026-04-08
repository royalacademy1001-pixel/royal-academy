import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentActions {

  static Future<void> approve(DocumentSnapshot doc) async {
    try {

      final data = doc.data() as Map<String, dynamic>? ?? {};

      final userId = data['userId'];
      final plan = data['plan'];
      final courseId = data['courseId'];

      if (userId == null) return;

      if (data['status'] == "approved") return;

      final firestore = FirebaseFirestore.instance;

      await firestore.runTransaction((transaction) async {

        final freshDoc = await transaction.get(doc.reference);
        final freshData =
            freshDoc.data() as Map<String, dynamic>? ?? {};

        if (freshData['status'] == "approved") return;

        transaction.update(doc.reference, {
          "status": "approved",
          "approvedAt": FieldValue.serverTimestamp(),
        });

        final userRef =
            firestore.collection("users").doc(userId);

        if (plan == "monthly") {

          final end =
              DateTime.now().add(const Duration(days: 30));

          transaction.set(userRef, {
            "subscribed": true,
            "subscriptionEnd": end.toIso8601String(),
          }, SetOptions(merge: true));

        } else if (plan == "yearly") {

          final end =
              DateTime.now().add(const Duration(days: 365));

          transaction.set(userRef, {
            "subscribed": true,
            "subscriptionEnd": end.toIso8601String(),
          }, SetOptions(merge: true));

        } else if (plan == "single_course" &&
            courseId != null) {

          transaction.set(userRef, {
            "unlockedCourses":
                FieldValue.arrayUnion([courseId])
          }, SetOptions(merge: true));
        }

        final notifRef =
            firestore.collection("notifications").doc();

        transaction.set(notifRef, {
          "userId": userId,
          "title": "تم تفعيل اشتراكك 🎉",
          "body": "تمت الموافقة على الدفع الخاص بك",
          "seen": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      debugPrint("✅ Payment Approved + User Updated");

    } catch (e) {
      debugPrint("🔥 APPROVE ERROR: $e");
      rethrow;
    }
  }

  static Future<void> reject(DocumentSnapshot doc) async {
    try {

      final data = doc.data() as Map<String, dynamic>? ?? {};

      if (data['status'] == "rejected") return;

      await doc.reference.update({
        "status": "rejected",
        "rejectedAt": FieldValue.serverTimestamp(),
      });

      final userId = data['userId'];

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection("notifications")
            .add({
          "userId": userId,
          "title": "تم رفض الدفع ❌",
          "body": "راجع بيانات الدفع وحاول مرة أخرى",
          "seen": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      debugPrint("❌ Payment Rejected");

    } catch (e) {
      debugPrint("🔥 REJECT ERROR: $e");
      rethrow;
    }
  }
}