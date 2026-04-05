import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_service.dart';

class NotificationSender {

  static Future<void> sendPaymentReminders() async {

    final users = await FirebaseService.firestore
        .collection("users")
        .get();

    final payments = await FirebaseService.firestore
        .collection("payments")
        .get();

    final Map<String, double> paidMap = {};

    for (var doc in payments.docs) {
      final data = doc.data();
      final userId = data['userId'];

      paidMap[userId] =
          (paidMap[userId] ?? 0) + (data['amount'] ?? 0);
    }

    const coursePrice = 500;

    for (var user in users.docs) {

      final data = user.data();

      if (data['isAdmin'] == true ||
          data['instructorApproved'] == true) continue;

      final paid = paidMap[user.id] ?? 0;
      final remaining = coursePrice - paid;

      if (remaining <= 0) continue;

      final token = data['fcmToken'];

      if (token == null || token.toString().isEmpty) continue;

      await FirebaseService.firestore
          .collection("notifications_queue")
          .add({
        "token": token,
        "title": "💰 تذكير بالدفع",
        "body": "عليك مبلغ $remaining جنيه، برجاء السداد",
        "createdAt": Timestamp.now(),
      });
    }
  }
}