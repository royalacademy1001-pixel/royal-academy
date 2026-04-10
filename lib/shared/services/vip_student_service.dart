import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../models/vip_student_model.dart';

class VipStudentService {
  static final _ref =
      FirebaseService.firestore.collection("vip_students");

  /// ✅ إضافة طالب يدوي
  static Future<void> addStudent(VipStudentModel student) async {
    await FirebaseInit.init();

    await _ref.add(student.toMap());
  }

  /// ✅ تعديل
  static Future<void> updateStudent(
      String id, Map<String, dynamic> data) async {
    await FirebaseInit.init();

    await _ref.doc(id).update(data);
  }

  /// ❌ حذف
  static Future<void> deleteStudent(String id) async {
    await FirebaseInit.init();

    await _ref.doc(id).delete();
  }

  /// 🔥 ربط بحساب
  static Future<void> linkStudent({
    required String studentId,
    required String userId,
  }) async {
    await FirebaseInit.init();

    await _ref.doc(studentId).update({
      "linkedUserId": userId,
    });
  }

  /// ❌ فك الربط
  static Future<void> unlinkStudent(String studentId) async {
    await FirebaseInit.init();

    await _ref.doc(studentId).update({
      "linkedUserId": null,
    });
  }

  /// 📊 Stream لكل الطلاب
  static Stream<List<VipStudentModel>> streamStudents() {
    return _ref.orderBy("createdAt", descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  VipStudentModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}