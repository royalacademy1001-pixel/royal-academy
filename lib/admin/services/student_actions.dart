import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class StudentActions {

  static Future enrollCourse(
      BuildContext context,
      String userId,
      String courseId) async {

    final ctx = context;

    try {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "enrolledCourses": FieldValue.arrayUnion([courseId])
      }, SetOptions(merge: true));

      if (!ctx.mounted) return;

      _show(ctx, "تم تسجيل الطالب ✅");

    } catch (e) {
      if (!ctx.mounted) return;
      _show(ctx, "حدث خطأ ❌");
    }
  }

  static Future unlockCourse(
      BuildContext context,
      String userId,
      String courseId) async {

    final ctx = context;

    try {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "unlockedCourses": FieldValue.arrayUnion([courseId])
      }, SetOptions(merge: true));

      if (!ctx.mounted) return;

      _show(ctx, "تم فتح الكورس 🔓");

    } catch (e) {
      if (!ctx.mounted) return;
      _show(ctx, "حدث خطأ ❌");
    }
  }

  static Future makeVip(
      BuildContext context,
      String userId) async {

    final ctx = context;

    try {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "subscribed": true,
      }, SetOptions(merge: true));

      if (!ctx.mounted) return;

      _show(ctx, "تم تفعيل الاشتراك ⭐");

    } catch (e) {
      if (!ctx.mounted) return;
      _show(ctx, "حدث خطأ ❌");
    }
  }

  static Future blockUser(
      BuildContext context,
      String userId,
      bool current) async {

    final ctx = context;

    try {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .update({
        "blocked": !current,
      });

      if (!ctx.mounted) return;

      _show(ctx,
          current ? "تم فك الحظر" : "تم حظر المستخدم 🚫");

    } catch (e) {
      if (!ctx.mounted) return;
      _show(ctx, "حدث خطأ ❌");
    }
  }

  static void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}