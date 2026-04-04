import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class StudentActions {

  static Future enrollCourse(
      BuildContext context,
      String userId,
      String courseId) async {

    await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .set({
      "enrolledCourses": FieldValue.arrayUnion([courseId])
    }, SetOptions(merge: true));

    _show(context, "تم تسجيل الطالب ✅");
  }

  static Future unlockCourse(
      BuildContext context,
      String userId,
      String courseId) async {

    await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .set({
      "unlockedCourses": FieldValue.arrayUnion([courseId])
    }, SetOptions(merge: true));

    _show(context, "تم فتح الكورس 🔓");
  }

  static Future makeVip(
      BuildContext context,
      String userId) async {

    await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .set({
      "subscribed": true,
    }, SetOptions(merge: true));

    _show(context, "تم تفعيل الاشتراك ⭐");
  }

  static Future blockUser(
      BuildContext context,
      String userId,
      bool current) async {

    await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .update({
      "blocked": !current,
    });

    _show(context,
        current ? "تم فك الحظر" : "تم حظر المستخدم 🚫");
  }

  static void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}