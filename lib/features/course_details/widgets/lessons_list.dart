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

    if (lessons.isEmpty) {
      return const Center(
        child: Text(
          "لا يوجد دروس",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];

        final data = lesson.data() as Map<String, dynamic>? ?? {};

        final canOpen = CoursePermissions.canOpenLesson(
          hasAccess: hasAccess,
          lessonData: data,
          isLoggedIn: isLoggedIn,
        );

        String videoUrl =
            (data['contentUrl'] ?? data['video'] ?? "").toString().trim();

        if (videoUrl == "null") videoUrl = "";

        final bool isFree = data['isFree'] == true;
        final String title = (data['title'] ?? "").toString();

        return RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              if (!canOpen) {
                showLockedDialog(context);
                return;
              }

              if (!context.mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPage(
                    title: title,
                    videoUrl: videoUrl,
                    courseId: courseId,
                    lessonId: lesson.id,
                    isFree: isFree,
                  ),
                ),
              );
            },
            child: LessonCard(
              lesson: lesson,
              data: data,
              canOpen: canOpen,
              isFree: isFree,
              isWatched: watched.contains(lesson.id),
              isLocked: !canOpen,
            ),
          ),
        );
      },
    );
  }
}