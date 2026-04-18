import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:royal_academy/core/firebase_service.dart';
import 'package:royal_academy/core/constants.dart';
import 'package:royal_academy/core/colors.dart';
import 'package:royal_academy/core/permission_service.dart';
import 'package:royal_academy/core/analytics_service.dart';

import 'package:royal_academy/features/courses/widgets/course_progress.dart';
import 'package:royal_academy/features/home/widgets/resume_button.dart';
import 'package:royal_academy/shared/widgets/skeleton_loader.dart';

import 'package:royal_academy/features/course_details/widgets/course_tabs.dart';
import 'package:royal_academy/features/course_details/widgets/lessons_list.dart';
import 'package:royal_academy/features/course_details/widgets/file_lessons_list.dart';

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
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _anim;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? courseData;

  List<QueryDocumentSnapshot> lessons = [];
  Set<String> watched = {};
  String? lastLessonId;

  bool hasAccess = false;
  bool loading = true;
  bool _canViewPage = true;

  int views = 0;
  int purchases = 0;

  final ScrollController _scrollController = ScrollController();
  double scrollOffset = 0;

  String resolvedImage = "";

  DateTime? _enterTime;

  bool _navLocked = false;

  @override
  void initState() {
    super.initState();

    _enterTime = DateTime.now();

    AnalyticsService.logScreen("course_details");

    _tabController = TabController(length: 3, vsync: this);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _anim.forward();

    _scrollController.addListener(() {
      if (!mounted) return;
      setState(() {
        scrollOffset = _scrollController.offset;
      });

      if (_scrollController.offset > 400) {
        AnalyticsService.logEvent("course_scroll_deep", params: {
          "courseId": widget.courseId,
        });
      }
    });

    loadAllData();
  }

  @override
  void dispose() {
    if (_enterTime != null) {
      final seconds =
          DateTime.now().difference(_enterTime!).inSeconds;

      AnalyticsService.logEvent("course_time_spent", params: {
        "courseId": widget.courseId,
        "seconds": seconds,
      });
    }

    _tabController.dispose();
    _anim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    final user = FirebaseService.auth.currentUser;

    try {
      await PermissionService.load();

      final results = await Future.wait([
        FirebaseService.firestore
            .collection(AppConstants.courses)
            .doc(widget.courseId)
            .get(),
        if (user != null)
          FirebaseService.firestore
              .collection(AppConstants.users)
              .doc(user.uid)
              .get(),
        FirebaseService.firestore
            .collection(AppConstants.courses)
            .doc(widget.courseId)
            .collection(AppConstants.lessons)
            .orderBy('order')
            .get(),
      ]);

      if (results.isEmpty) {
        hasAccess = false;
        _canViewPage = PermissionService.canAccess(
          role: PermissionService.getRole(userData),
          page: "courses",
        );
        loading = false;
        if (mounted) setState(() {});
        return;
      }

      final courseSnap = results[0] as DocumentSnapshot;
      courseData =
          courseSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};

      if (courseData != null && courseData!.isNotEmpty) {
        final raw = (courseData?['image'] ?? "").toString().trim();

        final dynamic versionValue =
            courseData?['imageUpdatedAt'] ??
                courseData?['updatedAt'] ??
                courseData?['modifiedAt'];

        String version = "";
        if (versionValue is Timestamp) {
          version = versionValue.millisecondsSinceEpoch.toString();
        } else if (versionValue != null) {
          version = versionValue.toString().trim();
        }

        final resolved =
            await FirebaseService.resolveImageUrl(raw, version: version);

        if (resolved.isNotEmpty && resolved.startsWith("http")) {
          resolvedImage =
              FirebaseService.fixImage(resolved, version: version);
        } else {
          resolvedImage = "";
        }
      }

      if (user != null && results.length > 2) {
        final userSnap = results[1] as DocumentSnapshot;
        userData =
            userSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      }

      lessons = (results.last as QuerySnapshot).docs;

      if (user != null) {
        final progressSnap = await FirebaseService.firestore
            .collection(AppConstants.progress)
            .where('userId', isEqualTo: user.uid)
            .where('courseId', isEqualTo: widget.courseId)
            .get();

        watched = progressSnap.docs
            .map((e) => (e['lessonId'] ?? "").toString())
            .where((e) => e.isNotEmpty)
            .toSet();

        if (progressSnap.docs.isNotEmpty) {
          lastLessonId =
              (progressSnap.docs.last['lessonId'] ?? "").toString();
          if (lastLessonId != null && lastLessonId!.isEmpty) {
            lastLessonId = null;
          }
        }
      }

      views = await AnalyticsService.getCourseViews(widget.courseId);
      purchases =
          await AnalyticsService.getCoursePurchases(widget.courseId);

      AnalyticsService.logEvent("course_opened", params: {
        "courseId": widget.courseId,
        "title": widget.title,
      });

      hasAccess = _calculateAccess(user);
      _canViewPage = PermissionService.canAccess(
        role: PermissionService.getRole(userData),
        page: "courses",
      );

      loading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _canViewPage = PermissionService.canAccess(
        role: PermissionService.getRole(userData),
        page: "courses",
      );
      loading = false;
      if (mounted) setState(() {});
    }
  }

  bool _calculateAccess(user) {
    if (user == null) return false;

    bool isAdmin = userData?['isAdmin'] == true;
    bool isVIP = userData?['isVIP'] == true;
    bool subscribed = userData?['subscribed'] == true;

    List unlocked = userData?['unlockedCourses'] ?? [];

    return isAdmin ||
        isVIP ||
        subscribed ||
        unlocked.contains(widget.courseId);
  }

  Widget _accessDenied() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.gold, size: 50),
              SizedBox(height: 16),
              Text(
                "غير مصرح بالدخول لهذه الصفحة",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header() {
    final image = resolvedImage;

    int total = lessons.length;
    int done = watched.length;
    double progress = total == 0 ? 0 : done / total;
    if (!progress.isFinite) progress = 0;

    double opacity = (scrollOffset / 200).clamp(0, 1);

    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: image.isEmpty
              ? Container(color: Colors.black)
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.black),
                ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.2 + opacity * 0.6),
                Colors.black.withOpacity(0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 15,
          right: 15,
          child: FadeTransition(
            opacity: _anim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        ),
        Positioned(
          top: 35,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_navLocked) return;
              _navLocked = true;
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 400), () {
                _navLocked = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget glassTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CourseTabs(controller: _tabController),
    );
  }

  Widget empty(String text) {
    return Center(
      child: Text(text,
          style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: SkeletonLoader());
    }

    if (!_canViewPage) {
      return _accessDenied();
    }

    final video =
        lessons.where((l) => (l['type'] ?? "video") == "video").toList();

    final pdf =
        lessons.where((l) => (l['type'] ?? "") == "pdf").toList();

    final audio =
        lessons.where((l) => (l['type'] ?? "") == "audio").toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          header(),
          glassTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                video.isEmpty
                    ? empty("لا يوجد فيديوهات")
                    : LessonsList(
                        lessons: video,
                        watched: watched,
                        hasAccess: hasAccess,
                        courseId: widget.courseId,
                      ),
                pdf.isEmpty
                    ? empty("لا يوجد ملفات PDF")
                    : FileLessonsList(
                        lessons: pdf,
                        hasAccess: hasAccess,
                        icon: Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                audio.isEmpty
                    ? empty("لا يوجد صوتيات")
                    : FileLessonsList(
                        lessons: audio,
                        hasAccess: hasAccess,
                        icon: Icons.headphones,
                        color: Colors.blue,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}