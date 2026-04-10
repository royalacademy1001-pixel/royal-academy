import '../../core/firebase_service.dart';

class AdminInitService {
  static Future<bool> checkAdmin() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return false;

    final doc = await FirebaseService.firestore
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    return data['isAdmin'] == true ||
        (data['role'] ?? "").toString().toLowerCase() == "admin";
  }
}