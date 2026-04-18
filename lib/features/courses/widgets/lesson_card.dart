import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/widgets/press_effect.dart';
import '../../../core/colors.dart';
import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import '../../quiz/student_quiz_page.dart';

import 'components/progress_bar.dart';
import 'components/quiz_badge.dart';

import '../services/lesson_guard.dart';
import '../services/lesson_xp.dart';
import '../services/lesson_actions.dart';

class LessonCard extends StatefulWidget {
  final QueryDocumentSnapshot lesson;
  final Map<String, dynamic> data;
  final bool canOpen;
  final bool isFree;
  final bool isWatched;
  final bool isLocked;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.data,
    required this.canOpen,
    required this.isFree,
    required this.isWatched,
    this.isLocked = false,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool loading = false;
  bool navigating = false;
  bool tapLocked = false;

  bool hasQuiz = false;
  bool quizSolved = false;

  double progressValue = 0;
  bool progressLoaded = false;

  static final Map<String, bool> quizCache = {};
  static final Map<String, double> progressCache = {};
  static final Map<String, bool> quizSolvedCache = {};

  @override
  void initState() {
    super.initState();
    checkQuizOnce();
    checkQuizSolved();
    loadProgress();
  }

  Future<void> checkQuizOnce() async {
    final lessonId = widget.lesson.id;

    if (quizCache.containsKey(lessonId)) {
      hasQuiz = quizCache[lessonId]!;
      if (mounted) setState(() {});
      return;
    }

    try {
      final snap = await FirebaseService.firestore
          .collection("quizzes")
          .where("lessonId", isEqualTo: lessonId)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      final exists = snap.docs.isNotEmpty;

      quizCache[lessonId] = exists;

      if (mounted) setState(() => hasQuiz = exists);
    } catch (e) {
      debugPrint("Quiz error: $e");
    }
  }

  Future<void> checkQuizSolved() async {
    final lessonId = widget.lesson.id;
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    if (quizSolvedCache.containsKey(lessonId)) {
      quizSolved = quizSolvedCache[lessonId]!;
      if (mounted) setState(() {});
      return;
    }

    final doc = await FirebaseService.firestore
        .collection("quiz_results")
        .doc("${user.uid}$lessonId")
        .get();

    final solved = doc.exists;

    quizSolvedCache[lessonId] = solved;

    if (mounted) setState(() => quizSolved = solved);
  }

  Future<void> loadProgress() async {
    final lessonId = widget.lesson.id;

    if (progressCache.containsKey(lessonId)) {
      progressValue = progressCache[lessonId]!;
      progressLoaded = true;
      if (mounted) setState(() {});
      return;
    }

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    final snap = await FirebaseService.firestore
        .collection(AppConstants.progress)
        .where('userId', isEqualTo: user.uid)
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    final val = snap.docs.isNotEmpty ? 1.0 : 0.0;

    progressCache[lessonId] = val;

    if (mounted) {
      setState(() {
        progressValue = val;
        progressLoaded = true;
      });
    }
  }

  void _showLockedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔒 اشترك لفتح باقي الدروس")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.data['title'] ?? "Lesson").toString();

    String url = (widget.data['contentUrl'] ?? widget.data['video'] ?? "")
        .toString()
        .trim();

    if (url == "null") url = "";

    return PressEffect(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: AppColors.premiumCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_fill, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                quizBadge(hasQuiz, quizSolved),
              ],
            ),
            if (progressLoaded) buildProgressBar(progressValue),
          ],
        ),
      ),
      onTap: () async {
        if (tapLocked || navigating) return;
        tapLocked = true;
        navigating = true;

        try {
          if (!LessonTapGuard.canTap(widget.lesson.id)) {
            tapLocked = false;
            navigating = false;
            return;
          }

          if (hasQuiz && !quizSolved) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizPage(lessonId: widget.lesson.id),
              ),
            );
          } else {
            await _handleTap(title, url);
          }
        } catch (_) {} finally {
          await Future.delayed(const Duration(milliseconds: 400));
          tapLocked = false;
          navigating = false;
        }
      },
    );
  }

  Future<void> _handleTap(String title, String url) async {
    if (!mounted) return;

    String courseId = widget.lesson.reference.parent.parent?.id ?? "";

    await Future.wait([
      safeLastWatch(
        courseId: courseId,
        lessonId: widget.lesson.id,
      ),
      LessonXP.reward(widget.lesson.id),
    ]);

    if (!mounted) return;

    await safeOpenVideo(
      context: context,
      title: title,
      url: url,
      courseId: courseId,
      lessonId: widget.lesson.id,
      isFree: widget.isFree,
    );
  }
}