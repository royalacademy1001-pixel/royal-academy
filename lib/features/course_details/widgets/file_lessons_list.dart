import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../logic/course_permissions.dart';
import 'locked_dialog.dart';
import '../../../core/firebase_service.dart';

class FileLessonsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> lessons;
  final bool hasAccess;
  final IconData icon;
  final Color color;

  const FileLessonsList({
    super.key,
    required this.lessons,
    required this.hasAccess,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseService.auth.currentUser != null;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...lessons.map((lesson) {
          final data = lesson.data() as Map<String, dynamic>? ?? {};

          final canOpen = CoursePermissions.canOpenLesson(
            hasAccess: hasAccess,
            lessonData: data,
            isLoggedIn: isLoggedIn,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                data['title'] ?? "",
                style: const TextStyle(color: Colors.white),
              ),
              leading: Icon(
                canOpen ? icon : Icons.lock_outline,
                color: canOpen ? color : Colors.grey,
              ),
              trailing: canOpen
                  ? null
                  : const Icon(Icons.lock, color: Colors.red),
              onTap: () {
                if (!canOpen) {
                  showLockedDialog(context);
                  return;
                }

                String url = (data['contentUrl'] ?? "").toString();
                if (url.isNotEmpty) {
                  launchUrl(Uri.parse(url));
                }
              },
            ),
          );
        }),
      ],
    );
  }
}