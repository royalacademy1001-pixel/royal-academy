import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:royal_academy/core/firebase_service.dart';

class NotificationSender {

  static Future<void> sendPaymentReminders() async {

    try {

      final firestore = FirebaseService.firestore;

      final usersSnap = await firestore.collection("users").get();
      final paymentsSnap = await firestore.collection("payments").get();

      final Map<String, double> paidMap = {};

      for (var doc in paymentsSnap.docs) {
        final data = doc.data();

        final userId = data['userId']?.toString();
        final amount = (data['amount'] ?? 0).toDouble();

        if (userId == null || userId.isEmpty) continue;

        paidMap[userId] = (paidMap[userId] ?? 0) + amount;
      }

      const double coursePrice = 500;

      final List<Map<String, dynamic>> notifications = [];

      for (var user in usersSnap.docs) {

        final data = user.data();

        final isAdmin = data['isAdmin'] == true;
        final isInstructor = data['instructorApproved'] == true;

        if (isAdmin || isInstructor) {
          continue;
        }

        final paid = paidMap[user.id] ?? 0;
        final remaining = coursePrice - paid;

        if (remaining <= 0) {
          continue;
        }

        final token = data['fcmToken']?.toString();

        if (token == null || token.isEmpty) {
          continue;
        }

        notifications.add({
          "token": token,
          "title": "💰 تذكير بالدفع",
          "body": "عليك مبلغ $remaining جنيه، برجاء السداد",
          "userId": user.id,
          "remaining": remaining,
          "createdAt": Timestamp.now(),
        });
      }

      if (notifications.isEmpty) {
        return;
      }

      final batch = firestore.batch();

      for (var notif in notifications) {
        final ref = firestore.collection("notifications_queue").doc();
        batch.set(ref, notif);
      }

      await batch.commit();

    } catch (e) {
      debugPrint("NotificationSender Error: $e");
    }
  }
}