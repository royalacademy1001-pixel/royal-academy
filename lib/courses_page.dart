// 🔥 IMPORTS FIRST
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'core/firebase_service.dart';
import 'core/constants.dart';
import 'core/colors.dart';

import 'course_details_page.dart';
import 'payment/payment_page.dart';

import 'widgets/loading_widget.dart';
import 'widgets/animated_course_card.dart';


/// 🔥🔥🔥 COURSES SUPER ENGINE UPGRADE 🔥🔥🔥
class CoursesCacheManager {
  static List<QueryDocumentSnapshot> cache = [];
  static DateTime? lastFetch;

  static bool isValid() {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch!).inSeconds < 30;
  }

  static void save(List<QueryDocumentSnapshot> data) {
    cache = data;
    lastFetch = DateTime.now();
  }
}

/// 🔥 NAVIGATION GUARD
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

String _fixImage(String url) {
  if (url.isEmpty) return "";
  return FirebaseService.fixImage(url);
}

bool _isVisibleCourse(Map<String, dynamic> data, bool isAdminUser) {
  if (isAdminUser) return true;
  final approved = data['approved'] == true;
  final status = (data['status'] ?? "").toString().toLowerCase();
  return approved || status == "approved";
}

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {

  String searchText = "";
  String selectedCategoryId = "All";

  Timer? _debounce;

  Map<String, dynamic>? userData;
  Map<String, String> categoryMap = {"All": "الكل"};

  List<QueryDocumentSnapshot> cachedCourses = [];

  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    _initCache();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (isLoadingMore) return;

    isLoadingMore = true;

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        limit += 10;
      });
    }

    isLoadingMore = false;
  }

  Future<void> _initCache() async {

    try {
      final user = FirebaseService.auth.currentUser;

      if (user != null) {
        final doc = await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(user.uid)
            .get();

        userData = doc.data() ?? {};
      }

      final catSnap = await FirebaseService.firestore
          .collection(AppConstants.categories)
          .orderBy("order")
          .get();

      for (var e in catSnap.docs) {
        var data = e.data();
        categoryMap[e.id] =
            (data['title'] ?? "Other").toString();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("🔥 Init Cache Error: $e");
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => searchText = value.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool hasAccess(String courseId) {
    bool isAdmin = userData?['isAdmin'] ?? false;
    bool subscribed = userData?['subscribed'] ?? false;

    List unlocked = userData?['unlockedCourses'] ?? [];
    List enrolled = userData?['enrolledCourses'] ?? [];

    return isAdmin ||
        subscribed ||
        unlocked.contains(courseId) ||
        enrolled.contains(courseId);
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;
    final bool isAdminUser = userData?['isAdmin'] == true;

    if (userData == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget()
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text("📚 Royal Academy",
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: Colors.black,
      ),

      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: const SizedBox()),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "ابحث عن طريق اسم الكورس...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.gold),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: categoryMap.entries.map((e) {
                    final selected = selectedCategoryId == e.key;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryId = e.key;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            if (selected) BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 8)
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore
                      .collection(AppConstants.courses)
                      .orderBy("createdAt", descending: true)
                      .limit(limit)
                      .snapshots(),
                  builder: (context, courseSnap) {

                    if (!courseSnap.hasData) {
                      return const LoadingWidget();
                    }

                    cachedCourses = List.from(courseSnap.data!.docs);
                    CoursesCacheManager.save(cachedCourses);

                    List<QueryDocumentSnapshot> courses =
                        List.from(cachedCourses);

                    courses = courses.where((c) {
                      final data = c.data() as Map<String, dynamic>;
                      return _isVisibleCourse(data, isAdminUser);
                    }).toList();

                    courses = courses.where((c) {
                      final data = c.data() as Map<String, dynamic>;

                      final title =
                          (data['title'] ?? "").toString().toLowerCase();

                      final matchesSearch =
                          searchText.isEmpty || title.contains(searchText);

                      final matchesCategory =
                          selectedCategoryId == "All" ||
                              (data['categoryId'] ?? "") == selectedCategoryId;

                      return matchesSearch && matchesCategory;
                    }).toList();

                    courses.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;

                      int aViews =
                          int.tryParse(aData['views']?.toString() ?? "0") ?? 0;
                      int bViews =
                          int.tryParse(bData['views']?.toString() ?? "0") ?? 0;

                      Timestamp? aTime = aData['createdAt'];
                      Timestamp? bTime = bData['createdAt'];

                      if (aViews != bViews) {
                        return bViews.compareTo(aViews);
                      }

                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;

                      return bTime.compareTo(aTime);
                    });

                    if (courses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_stories_outlined, color: Colors.white.withValues(alpha: 0.2), size: 80),
                            const SizedBox(height: 15),
                            const Text("لا توجد كورسات متاحة حالياً", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: user == null
                          ? const Stream.empty()
                          : FirebaseService.firestore
                              .collection(AppConstants.progress)
                              .where('userId', isEqualTo: user.uid)
                              .snapshots(),
                      builder: (context, progressSnap) {

                        Map<String, int> progressMap = {};

                        if (progressSnap.hasData) {
                          for (var doc in progressSnap.data!.docs) {
                            var d = doc.data() as Map<String, dynamic>;
                            String courseId =
                                (d['courseId'] ?? "").toString();

                            if (courseId.isEmpty) continue;

                            progressMap[courseId] =
                                (progressMap[courseId] ?? 0) + 1;
                          }
                        }

                        final Map<String,
                            List<QueryDocumentSnapshot>> grouped = {};

                        for (var c in courses) {
                          var data = c.data() as Map<String, dynamic>;

                          String catId =
                              (data['categoryId'] ?? "unknown").toString();

                          grouped.putIfAbsent(catId, () => []);
                          grouped[catId]!.add(c);
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 10, bottom: 80),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {

                            String catId =
                                grouped.keys.elementAt(index);

                            var list = grouped[catId]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        categoryMap[catId] ?? "تصنيف غير معروف",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                        child: Text("${list.length}", style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ),

                                SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    itemCount: list.length,
                                    itemBuilder: (context, i) {

                                      var c = list[i];
                                      var data =
                                          c.data() as Map<String, dynamic>;

                                      data["image"] =
                                          _fixImage((data["image"] ?? "").toString());

                                      final bool access = hasAccess(c.id) || (data['isFree'] == true);

                                      return _courseCard(
                                        index: i,
                                        id: c.id,
                                        data: data,
                                        doneLessons:
                                            progressMap[c.id] ?? 0,
                                        hasAccess: access,
                                        onTap: () {
                                          _NavGuard.go(() {

                                            if (!access) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const PaymentPage(),
                                                ),
                                              );
                                              return;
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseDetailsPage(
                                                  title:
                                                      (data['title'] ?? "").toString(),
                                                  courseId: c.id,
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _courseCard({
    required int index,
    required String id,
    required Map<String, dynamic> data,
    required int doneLessons,
    required bool hasAccess,
    required VoidCallback onTap,
  }) {
    final String title = (data['title'] ?? "").toString();
    final String image = (data['image'] ?? "").toString();
    final String categoryId = (data['categoryId'] ?? "").toString();
    final String categoryName = categoryMap[categoryId] ?? "بدون تصنيف";
    final String level = (data['level'] ?? "").toString();
    final String videoCount = (data['videosCount'] ?? data['lessonsCount'] ?? data['videos'] ?? "فيديو").toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 235,
        margin: const EdgeInsets.only(right: 10, bottom: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasAccess ? AppColors.gold.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFF1A1A1A),
                        child: Center(
                          child: Icon(
                            Icons.video_library_rounded,
                            color: AppColors.gold.withValues(alpha: 0.5),
                            size: 42,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.gold.withValues(alpha: 0.5),
                              size: 42,
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
              ),
              if (!hasAccess)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "مقفل",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? "كورس بدون عنوان" : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.gold.withValues(alpha: 0.95),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (level.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "$videoCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (doneLessons > 0)
                          Text(
                            "$doneLessons مشاهدة",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}