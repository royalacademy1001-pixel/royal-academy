import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentFilters {

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> filter({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String status,
    required String query,
  }) {

    final safeQuery = query.toLowerCase().trim();

    return docs.where((doc) {

      final data = doc.data();

      final paymentStatus =
          (data['status'] ?? "").toString().toLowerCase();

      final email =
          (data['email'] ?? "").toString().toLowerCase();

      final phone =
          (data['phone'] ?? "").toString().toLowerCase();

      final courseId =
          (data['courseId'] ?? "").toString().toLowerCase();

      bool matchStatus;

      if (status == "all") {
        matchStatus = true;
      } else {
        matchStatus = paymentStatus == status.toLowerCase();
      }

      bool matchSearch;

      if (safeQuery.isEmpty) {
        matchSearch = true;
      } else {
        matchSearch = email.contains(safeQuery) ||
            phone.contains(safeQuery) ||
            courseId.contains(safeQuery);
      }

      return matchStatus && matchSearch;

    }).toList();
  }
}