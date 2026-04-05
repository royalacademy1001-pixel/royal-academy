import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../video_page.dart';
import 'reviews_page.dart';
import '../admin/add_lesson_page.dart';
import '../payment/payment_page.dart';
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/analytics_service.dart';
import '../widgets/course_progress.dart';
import '../widgets/resume_button.dart';
import '../widgets/lesson_card.dart';
import '../widgets/loading_widget.dart';

void cleanCourseCache() {
  if (_CourseDetailsPageState._courseCache.length > 10) {
    _CourseDetailsPageState._courseCache.clear();
  }
  if (_CourseDetailsPageState._lessonCache.length > 10) {
    _CourseDetailsPageState._lessonCache.clear();
  }
}

Widget fadeItem(Widget child) {
  return TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 250),
    tween: Tween(begin: 0.95, end: 1.0),
    builder: (context, value, widget) =>
        Transform.scale(scale: value, child: widget),
    child: child,
  );
}

class _NavGuard {
  static bool navigating = false;

  static void go(VoidCallback action) {
    if (navigating) return;
    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("🔥 Navigation Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      navigating = false;
    });
  }
}

class CourseDetailsPage extends StatefulWidget {
  final String title;
  final String courseId;

  const CourseDetailsPage({
    super.key,
    required this.title,
    required this.courseId,
  });

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? courseData;

  List<QueryDocumentSnapshot> lessons = [];
  Set<String> watched = {};
  String? lastLessonId;
  bool hasAccess = false;

  bool loading = true;

  int views = 0;
  int purchases = 0;

  static final Map<String, dynamic> _courseCache = {};
  static final Map<String, List<QueryDocumentSnapshot>> _lessonCache = {};

  @override
  void initState() {
    super.initState();
    cleanCourseCache();

    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      AnalyticsService.logCourseView(widget.courseId, title: widget.title);
      FirebaseService.firestore.collection("analytics_events").add({
        "type": "course_view",
        "courseId": widget.courseId,
        "courseTitle": widget.title,
        "userId": FirebaseService.auth.currentUser?.uid ?? "",
        "timestamp": Timestamp.now(),
      });
    });

    loadData();
    loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadStats() async {
    views = await AnalyticsService.getCourseViews(widget.courseId);
    purchases = await AnalyticsService.getCoursePurchases(widget.courseId);
    if (mounted) setState(() {});
  }

  Future<void> loadData() async {
    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      if (_courseCache.containsKey(widget.courseId)) {
        courseData = _courseCache[widget.courseId];
      }

      final results = await Future.wait([
        FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(user.uid)
            .get(),
        courseData == null
            ? FirebaseService.firestore
                .collection(AppConstants.courses)
                .doc(widget.courseId)
                .get()
            : Future.value(null),
      ]);

      userData =
          (results[0] as DocumentSnapshot).data() as Map<String, dynamic>? ??
              {};

      if (courseData == null && results[1] != null) {
        courseData =
            (results[1] as DocumentSnapshot).data() as Map<String, dynamic>? ??
                {};

        _courseCache[widget.courseId] = courseData!;
      }

      if (!mounted) return;
      setState(() => loading = false);

      await loadExtra(user.uid);
    } catch (e) {
      debugPrint("🔥 Load Data Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadExtra(String userId) async {
    try {
      if (_lessonCache.containsKey(widget.courseId)) {
        lessons = _lessonCache[widget.courseId]!;
      }

      final results = await Future.wait([
        FirebaseService.firestore
            .collection(AppConstants.progress)
            .where('userId', isEqualTo: userId)
            .where('courseId', isEqualTo: widget.courseId)
            .get(),
        lessons.isEmpty
            ? FirebaseService.firestore
                .collection(AppConstants.courses)
                .doc(widget.courseId)
                .collection(AppConstants.lessons)
                .orderBy('order')
                .get()
            : Future.value(null),
        FirebaseService.firestore
            .collection(AppConstants.lastWatch)
            .where('userId', isEqualTo: userId)
            .where('courseId', isEqualTo: widget.courseId)
            .limit(1)
            .get(),
      ]);

      watched = (results[0] as QuerySnapshot)
          .docs
          .map((e) => (e['lessonId'] ?? "").toString())
          .toSet();

      if (results[1] != null) {
        lessons = List.from((results[1] as QuerySnapshot).docs);

        lessons.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

        _lessonCache[widget.courseId] = lessons;
      }

      final lastSnap = results[2] as QuerySnapshot;

      if (lastSnap.docs.isNotEmpty) {
        lastLessonId = (lastSnap.docs.first['lessonId'] ?? "").toString();
      }

      if (lastLessonId != null && !watched.contains(lastLessonId)) {
        lastLessonId = null;
      }

      calculateAccess(userId);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("🔥 Load Extra Error: $e");
    }
  }

  void calculateAccess(String userId) {
    bool isAdmin = userData?['isAdmin'] == true;
    bool subscribed = userData?['subscribed'] == true;
    bool blocked = userData?['blocked'] == true;
    bool instructorApproved = userData?['instructorApproved'] == true;

    bool validSubscription = false;

    final endDate = userData?['subscriptionEnd'];

    if (endDate != null) {
      try {
        validSubscription =
            DateTime.parse(endDate.toString()).isAfter(DateTime.now());
      } catch (_) {}
    }

    if (isAdmin) {
      subscribed = true;
      validSubscription = true;
    }

    List unlocked = userData?['unlockedCourses'] ?? [];
    List enrolled = userData?['enrolledCourses'] ?? [];

    hasAccess = !blocked &&
        (isAdmin ||
            instructorApproved ||
            (subscribed && validSubscription) ||
            unlocked.contains(widget.courseId) ||
            enrolled.contains(widget.courseId));
  }

  Widget safeImage(String image) {
    if (image.isEmpty) {
      return Container(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          FirebaseService.fixImage(image),
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        )
      ],
    );
  }

  bool get canEditCourse {
    bool isAdmin = userData?['isAdmin'] == true;
    bool isInstructor = userData?['instructorApproved'] == true;
    return isAdmin || isInstructor;
  }

  bool _canOpenLesson(QueryDocumentSnapshot lesson) {
    if (courseData?['isFree'] == true) return true;
    if (hasAccess) return true;
    final data = lesson.data() as Map<String, dynamic>? ?? {};
    if (data['isFree'] == true) return true;
    if (lessons.isEmpty) return false;
    return lessons.first.id == lesson.id;
  }

  void _showLockedLessonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: const Text(
            "🔒 الدرس مقفول",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "اشترك لفتح باقي الدروس",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: AppColors.goldButton,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentPage(),
                  ),
                );
              },
              child: const Text("اشترك الآن"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: LoadingWidget());
    }

    String image = (courseData?['image'] ?? "").toString();

    int total = lessons.length;
    int done = watched.length > total ? total : watched.length;
    double progress = total == 0 ? 0 : done / total;

    List<QueryDocumentSnapshot> videoLessons = lessons.where((l) {
      var d = l.data() as Map<String, dynamic>? ?? {};
      return (d['type'] ?? "video") == "video";
    }).toList();

    List<QueryDocumentSnapshot> pdfLessons = lessons.where((l) {
      var d = l.data() as Map<String, dynamic>? ?? {};
      return (d['type'] ?? "") == "pdf";
    }).toList();

    List<QueryDocumentSnapshot> audioLessons = lessons.where((l) {
      var d = l.data() as Map<String, dynamic>? ?? {};
      return (d['type'] ?? "") == "audio";
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canEditCourse
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLessonPage(
                      courseId: widget.courseId,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: safeImage(image),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (canEditCourse)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddLessonPage(
                            courseId: widget.courseId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: fadeItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("👁 $views",
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(width: 15),
                          Text("💰 $purchases",
                              style: const TextStyle(color: AppColors.gold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CourseProgress(
                        progress: progress,
                        done: done,
                        total: total,
                      ),
                      const SizedBox(height: 10),
                      if (lastLessonId != null)
                        ResumeButton(
                          lessonId: lastLessonId!,
                          courseId: widget.courseId,
                          hasAccess: hasAccess,
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: AppColors.goldButton,
                        onPressed: () {
                          _NavGuard.go(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReviewsPage(courseId: widget.courseId),
                              ),
                            );
                          });
                        },
                        child: const Text("⭐ التقييمات"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.4),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.gold,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.gold,
              tabs: const [
                Tab(text: "الفيديوهات"),
                Tab(text: "PDF"),
                Tab(text: "الصوتيات"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    ...videoLessons.map((lesson) {
                      var data = lesson.data() as Map<String, dynamic>? ?? {};
                      final canOpenLesson = _canOpenLesson(lesson);

                      String videoUrl =
                          (data['contentUrl'] ?? data['video'] ?? "")
                              .toString();

                      if (videoUrl == "null") videoUrl = "";

                      return fadeItem(
                        GestureDetector(
                          onTap: () {
                            if (!canOpenLesson) {
                              _showLockedLessonDialog();
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPage(
                                  title: data['title'] ?? "",
                                  videoUrl: videoUrl,
                                  courseId: widget.courseId,
                                  lessonId: lesson.id,
                                  isFree: data['isFree'] == true ||
                                      lessons.isNotEmpty &&
                                          lessons.first.id == lesson.id,
                                ),
                              ),
                            );
                          },
                          child: LessonCard(
                            lesson: lesson,
                            data: data,
                            canOpen: canOpenLesson,
                            isFree: data['isFree'] == true ||
                                lessons.isNotEmpty &&
                                    lessons.first.id == lesson.id,
                            isWatched: watched.contains(lesson.id),
                            isLocked: !canOpenLesson,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    ...pdfLessons.map((lesson) {
                      var data = lesson.data() as Map<String, dynamic>? ?? {};
                      final canOpenLesson = _canOpenLesson(lesson);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(data['title'] ?? "",
                              style: const TextStyle(color: Colors.white)),
                          leading: Icon(
                            canOpenLesson
                                ? Icons.picture_as_pdf
                                : Icons.lock_outline,
                            color: canOpenLesson ? Colors.red : Colors.grey,
                          ),
                          trailing: canOpenLesson
                              ? null
                              : const Icon(Icons.lock, color: Colors.red),
                          onTap: () {
                            if (!canOpenLesson) {
                              _showLockedLessonDialog();
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
                ),
                ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    ...audioLessons.map((lesson) {
                      var data = lesson.data() as Map<String, dynamic>? ?? {};
                      final canOpenLesson = _canOpenLesson(lesson);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(data['title'] ?? "",
                              style: const TextStyle(color: Colors.white)),
                          leading: Icon(
                            canOpenLesson
                                ? Icons.headphones
                                : Icons.lock_outline,
                            color: canOpenLesson ? Colors.blue : Colors.grey,
                          ),
                          trailing: canOpenLesson
                              ? null
                              : const Icon(Icons.lock, color: Colors.red),
                          onTap: () {
                            if (!canOpenLesson) {
                              _showLockedLessonDialog();
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}