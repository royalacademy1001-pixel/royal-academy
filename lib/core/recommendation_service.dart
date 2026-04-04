import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'constants.dart';

class RecommendationService {

  /// 🔥 يجيب كورسات مقترحة للمستخدم
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getRecommendedCourses(String userId) async {

    final userDoc = await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .get();

    final userData = userDoc.data();

    List enrolled = userData?['enrolledCourses'] ?? [];
    List unlocked = userData?['unlockedCourses'] ?? [];

    /// 🔥 الكورسات اللي المستخدم مش داخلها
    final coursesSnap = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .get();

    List<QueryDocumentSnapshot<Map<String, dynamic>>> allCourses =
        coursesSnap.docs;

    /// 🔥 فلترة
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered =
        allCourses.where((c) {
      return !enrolled.contains(c.id) &&
             !unlocked.contains(c.id);
    }).toList();

    /// 🔥 ترتيب (ممكن تزوده ذكاء بعدين)
    filtered.shuffle();

    return filtered.take(5).toList();
  }
}