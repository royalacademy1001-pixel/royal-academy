import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../features/video/pages/video_page.dart';

/// 🔥 OPEN VIDEO
Future<void> safeOpenVideo({
  required BuildContext context,
  required String title,
  required String url,
  required String courseId,
  required String lessonId,
  required bool isFree,
}) async {
  try {
    if (!context.mounted) return;

    if (url.trim().isEmpty) {
      debugPrint("❌ Empty URL");
      return;
    }

    final user = FirebaseService.auth.currentUser;

    /// 🔒 حماية الكورس
    if (!isFree) {
      if (user == null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ لازم تسجل دخول")),
        );
        return;
      }

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      final isAdmin = data['isAdmin'] == true;
      final isVIP = data['isVIP'] == true;
      final unlockedCourses = (data['unlockedCourses'] ?? []) as List;

      final hasAccess =
          isAdmin || isVIP || unlockedCourses.contains(courseId);

      if (!hasAccess) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔒 اشترك لفتح الدرس"),
          ),
        );
        return;
      }
    }

    /// 🔥 تنظيف رابط اليوتيوب
    String cleanUrl = url;
    final uri = Uri.tryParse(url);

    if (uri != null) {
      if (uri.host.contains("youtu.be")) {
        final id =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.first : "";
        if (id.isNotEmpty) {
          cleanUrl = "https://www.youtube.com/watch?v=$id";
        }
      }

      if (uri.queryParameters.containsKey("v")) {
        cleanUrl =
            "https://www.youtube.com/watch?v=${uri.queryParameters["v"]}";
      }
    }

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPage(
          title: title,
          videoUrl: cleanUrl,
          courseId: courseId,
          lessonId: lessonId,
          isFree: isFree,
        ),
      ),
    );
  } catch (e) {
    debugPrint("🔥 Navigation Error: $e");
  }
}

/// 🔥 OPEN LINK (خارجي)
Future<void> safeLaunch(String url) async {
  try {
    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      debugPrint("❌ Invalid URL: $url");
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint("Launch Error: $e");
  }
}

/// 🔥 LAST WATCH (حفظ آخر مشاهدة)
Future<void> safeLastWatch({
  required String courseId,
  required String lessonId,
}) async {
  try {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    await FirebaseService.firestore
        .collection(AppConstants.lastWatch)
        .doc("${user.uid}$courseId")
        .set({
      "userId": user.uid,
      "courseId": courseId,
      "lessonId": lessonId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint("LastWatch Error: $e");
  }
}