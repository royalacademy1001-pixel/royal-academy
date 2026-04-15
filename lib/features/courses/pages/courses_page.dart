import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:royal_academy/core/firebase_service.dart';
import 'package:royal_academy/core/constants.dart';
import 'package:royal_academy/core/colors.dart';
import 'package:royal_academy/core/permission_service.dart';
import 'package:royal_academy/shared/services/analytics_service.dart';
import 'package:royal_academy/payment/payment_page.dart';
import 'package:royal_academy/course_details_page.dart';


import '../logic/nav_guard.dart';
import '../logic/course_helpers.dart';
import '../widgets/search_bar.dart';
import '../widgets/category_filter.dart';
import '../widgets/courses_list.dart';
import '../widgets/advanced_filter.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String search = "";
  String selected = "All";

  String selectedLevel = "All";
  String selectedPrice = "All";
  String selectedSort = "popular";

  Map<String, dynamic>? userData;
  Map<String, String> categories = {"All": "الكل"};

  bool _canViewPage = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen("courses");
    loadData();
    loadCategories();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      await PermissionService.load();
    } catch (_) {}

    if (!mounted) return;
    _syncPageAccess();
  }

  void _syncPageAccess() {
    final role = PermissionService.getRole(userData);
    _canViewPage = PermissionService.canAccess(role: role, page: "courses");

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadData() async {
    try {
      final user = FirebaseService.auth.currentUser;

      if (user != null) {
        final doc = await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(user.uid)
            .get();

        userData = doc.data();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {});
    _syncPageAccess();
  }

  Future<void> loadCategories() async {
    try {
      final snap = await FirebaseService.firestore
          .collection(AppConstants.categories)
          .orderBy("order")
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        categories[doc.id] = (data['title'] ?? "Other").toString();
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  bool hasAccess(String id) {
    final role = PermissionService.getRole(userData);

    if (!PermissionService.canAccess(role: role, page: "courses")) {
      return false;
    }

    final bool isAdmin = userData?['isAdmin'] == true;
    final bool isVIP = userData?['isVIP'] == true;
    final bool subscribed = userData?['subscribed'] == true;

    final List unlocked = userData?['unlockedCourses'] ?? [];
    final List enrolled = userData?['enrolledCourses'] ?? [];

    return isAdmin ||
        isVIP ||
        subscribed ||
        unlocked.contains(id) ||
        enrolled.contains(id);
  }

  Widget _deniedView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "📚 Courses",
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "🚫 غير مصرح بالدخول لهذه الصفحة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canViewPage) {
      return _deniedView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("📚 Courses",
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            SearchBarWidget(
              onChanged: (v) {
                AnalyticsService.logEvent("courses_search", params: {"q": v});
                setState(() => search = v);
              },
            ),
            const SizedBox(height: 10),
            CategoryFilter(
              categories: categories,
              selected: selected,
              onSelect: (v) {
                AnalyticsService.logEvent("courses_category", params: {"cat": v});
                setState(() => selected = v);
              },
            ),
            const SizedBox(height: 10),
            AdvancedFilter(
              level: selectedLevel,
              price: selectedPrice,
              sort: selectedSort,
              onLevel: (v) {
                AnalyticsService.logEvent("courses_level", params: {"level": v});
                setState(() => selectedLevel = v);
              },
              onPrice: (v) {
                AnalyticsService.logEvent("courses_price", params: {"price": v});
                setState(() => selectedPrice = v);
              },
              onSort: (v) {
                AnalyticsService.logEvent("courses_sort", params: {"sort": v});
                setState(() => selectedSort = v);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection(AppConstants.courses)
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData || snap.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final raw = snap.data!.docs;

                  final List<QueryDocumentSnapshot> filtered = raw.where((c) {
                    final data = (c.data() as Map<String, dynamic>? ?? {});

                    if (data.isEmpty) return false;

                    final level = (data['level'] ?? "").toString().toLowerCase();
                    final isFree = data['isFree'] == true;

                    final matchesLevel =
                        selectedLevel == "All" ||
                            level == selectedLevel.toLowerCase();

                    final matchesPrice =
                        selectedPrice == "All" ||
                            (selectedPrice == "free" && isFree) ||
                            (selectedPrice == "paid" && !isFree);

                    final matchesSearch = matchSearch(data, search);

                    final matchesCategory =
                        selected == "All" ||
                            (data['categoryId'] ?? "") == selected;

                    final visible = isVisibleCourse(
                      data,
                      PermissionService.getRole(userData) == "admin",
                    );

                    return matchesSearch &&
                        matchesCategory &&
                        matchesLevel &&
                        matchesPrice &&
                        visible;
                  }).toList().cast<QueryDocumentSnapshot>();

                  final List<QueryDocumentSnapshot> courses = sortCourses(
                    filtered,
                    sort: selectedSort,
                  ).cast<QueryDocumentSnapshot>();

                  if (courses.isEmpty) {
                    return Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_stories,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 10),
                            const Text(
                              "لا يوجد كورسات",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: CoursesList(
                      courses: courses,
                      hasAccess: hasAccess,
                      onTap: (c) {
                        final data = (c.data() as Map<String, dynamic>? ?? {});

                        if (data.isEmpty) return;

                        AnalyticsService.logCourseView(
                          c.id,
                          title: (data['title'] ?? "").toString(),
                        );

                        NavGuard.go(() {
                          if (!hasAccess(c.id) &&
                              data['isFree'] != true) {
                            AnalyticsService.logEvent("course_paywall");
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PaymentPage()),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailsPage(
                                title: (data['title'] ?? "").toString(),
                                courseId: c.id,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}