import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class StatsService {
  static Future<int> getCourseStudents(String courseId) async {
    try {
      await FirebaseInit.init();

      final snap = await FirebaseService.firestore
          .collection(AppConstants.users)
          .where("enrolledCourses", arrayContains: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getCourseViews(String courseId) async {
    try {
      await FirebaseInit.init();

      final snap = await FirebaseService.firestore
          .collection("analytics_events")
          .where("type", isEqualTo: "course_view")
          .where("courseId", isEqualTo: courseId)
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getInstructorTotalStudents(String instructorId) async {
    try {
      await FirebaseInit.init();

      final courses = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .where("instructorId", isEqualTo: instructorId)
          .get();

      int total = 0;

      for (final c in courses.docs) {
        final count = await getCourseStudents(c.id);
        total += count;
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getInstructorTotalViews(String instructorId) async {
    try {
      await FirebaseInit.init();

      final courses = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .where("instructorId", isEqualTo: instructorId)
          .get();

      int total = 0;

      for (final c in courses.docs) {
        final count = await getCourseViews(c.id);
        total += count;
      }

      return total;
    } catch (_) {
      return 0;
    }
  }
}
