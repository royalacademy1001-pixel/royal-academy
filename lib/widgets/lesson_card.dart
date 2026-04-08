// 🔥 IMPORTS FIRST
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/press_effect.dart';
import '../core/colors.dart';
import '../video_page.dart';
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../features/quiz/student_quiz_page.dart';

// 🔥🔥🔥 ULTRA LESSON CARD FINAL UPGRADE 🔥🔥🔥

Widget buildProgressBar(double value) {
  return Container(
    height: 4,
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(10),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: value.clamp(0, 1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

Widget quizBadge(bool hasQuiz, bool solved) {
  if (!hasQuiz) return const SizedBox();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: solved ? Colors.green : Colors.orange,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      solved ? "✔ Quiz" : "Quiz",
      style: const TextStyle(fontSize: 10, color: Colors.white),
    ),
  );
}

// 🔥 TAP GUARD
class LessonTapGuard {
  static final Map<String, DateTime> _locks = {};

  static bool canTap(String key) {
    final now = DateTime.now();

    if (_locks.containsKey(key)) {
      if (now.difference(_locks[key]!).inMilliseconds < 800) {
        return false;
      }
    }

    _locks[key] = now;
    return true;
  }
}

// 🔥 XP
class LessonXP {
  static Future<void> reward(String lessonId) async {
    try {
      if (!FirebaseService.canAddXP(lessonId)) return;

      await FirebaseService.addXP(
        AppConstants.xpPerLesson,
      );
    } catch (e) {
      debugPrint("XP Error: $e");
    }
  }
}

// 🔥 OPEN VIDEO (UPGRADED)
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

    // 🔒 حماية الكورسات
    if (!isFree) {
      if (user == null) {
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

      final hasAccess = isAdmin || isVIP || unlockedCourses.contains(courseId);

      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔒 اشترك لفتح الدرس"),
          ),
        );
        return;
      }
    }

    String cleanUrl = url;

    final uri = Uri.tryParse(url);

    if (uri != null) {
      if (uri.host.contains("youtu.be")) {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : "";
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

// 🔥 OPEN LINK
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

// 🔥 LAST WATCH
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

// 🔥 FINAL LESSON CARD

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

      if (mounted) {
        setState(() => hasQuiz = exists);
      }
    } catch (e) {
      debugPrint("Quiz check error: $e");
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

    try {
      final doc = await FirebaseService.firestore
          .collection("quiz_results")
          .doc("${user.uid}$lessonId")
          .get();

      final solved = doc.exists;

      quizSolvedCache[lessonId] = solved;

      if (mounted) setState(() => quizSolved = solved);
    } catch (_) {}
  }

  Future<void> loadProgress() async {
    final lessonId = widget.lesson.id;

    if (progressCache.containsKey(lessonId)) {
      progressValue = progressCache[lessonId]!;
      progressLoaded = true;
      if (mounted) setState(() {});
      return;
    }

    try {
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
    } catch (e) {
      debugPrint("Progress error: $e");
    }
  }

  void _showLockedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔒 اشترك لفتح باقي الدروس"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.data['title'] ?? "Lesson").toString();

    String url = (widget.data['contentUrl'] ?? widget.data['video'] ?? "")
        .toString()
        .trim();

    if (url == "null") url = "";

    IconData mainIcon = widget.isLocked
        ? Icons.lock
        : widget.isWatched
            ? Icons.check_circle
            : Icons.play_circle_fill;

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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isLocked
                          ? Colors.red.withValues(alpha: 0.2)
                          : AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mainIcon,
                        color: widget.isLocked ? Colors.red : AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isLocked ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  quizBadge(hasQuiz, quizSolved),
                  if (widget.isLocked)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock, color: Colors.red, size: 16),
                    ),
                ],
              ),
              if (progressLoaded) buildProgressBar(progressValue),
            ],
          ),
        ),
        onTap: () async {
          if (!widget.canOpen || widget.isLocked) {
            _showLockedMessage();
            return;
          }

          if (FirebaseService.auth.currentUser == null && !widget.isFree) {
            _showLockedMessage();
            return;
          }

          if (loading || navigating || tapLocked) return;
          if (!LessonTapGuard.canTap(widget.lesson.id)) return;

          tapLocked = true;

          try {
            if (hasQuiz && !quizSolved) {
              if (!mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizPage(
                    lessonId: widget.lesson.id,
                  ),
                ),
              );
            } else {
              await _handleTap(title, url);
            }

            if (!mounted) return;

            // 🔥 تحديث سريع بدون lag
            Future.wait([
              loadProgress(),
              checkQuizSolved(),
            ]);
          } catch (e) {
            debugPrint("Tap Error: $e");
          }

          tapLocked = false;
        });
  }

  Future<void> _handleTap(String title, String url) async {
    if (loading || navigating) return;

    if (!mounted) return;

    setState(() => loading = true);

    try {
      navigating = true;

      String courseId = "";
      try {
        courseId = widget.lesson.reference.parent.parent?.id ?? "";
      } catch (_) {}

      // 🔥 تشغيل العمليات مع بعض (أسرع)
      await Future.wait([
        safeLastWatch(
          courseId: courseId,
          lessonId: widget.lesson.id,
        ),
        LessonXP.reward(widget.lesson.id),
      ]);

      // 🔥 أهم سطر (حل crash context)
      if (!mounted) return;

      await safeOpenVideo(
        context: context,
        title: title,
        url: url,
        courseId: courseId,
        lessonId: widget.lesson.id,
        isFree: widget.isFree,
      );
    } catch (e) {
      debugPrint("🔥 Open error: $e");
    } finally {
      navigating = false;

      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
