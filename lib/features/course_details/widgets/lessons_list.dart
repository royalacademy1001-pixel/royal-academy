import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';
import '../../../features/video/pages/video_page.dart';
import 'package:royal_academy/features/courses/widgets/lesson_card.dart';
import '../logic/course_permissions.dart';
import 'package:royal_academy/features/course_details/widgets/locked_dialog.dart';

class LessonsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> lessons;
  final Set<String> watched;
  final bool hasAccess;
  final String courseId;

  const LessonsList({
    super.key,
    required this.lessons,
    required this.watched,
    required this.hasAccess,
    required this.courseId,
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

          String videoUrl =
              (data['contentUrl'] ?? data['video'] ?? "").toString();

          if (videoUrl == "null") videoUrl = "";

          return GestureDetector(
            onTap: () {
              if (!canOpen) {
                showLockedDialog(context);
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPage(
                    title: data['title'] ?? "",
                    videoUrl: videoUrl,
                    courseId: courseId,
                    lessonId: lesson.id,
                    isFree: data['isFree'] == true,
                  ),
                ),
              );
            },
            child: LessonCard(
              lesson: lesson,
              data: data,
              canOpen: canOpen,
              isFree: data['isFree'] == true,
              isWatched: watched.contains(lesson.id),
              isLocked: !canOpen,
            ),
          );
        }),
      ],
    );
  }
}