// 🔥 STUDENT DASHBOARD PRO MAX

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 CORE
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

// 🔥 PAGES
import '../features/courses/pages/courses_page.dart';
import '../student_profile_page.dart';
import '../course_details_page.dart';
import '../payment/payment_page.dart';

// 🔥 WIDGETS
import '/shared/widgets/loading_widget.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {

  Map<String, dynamic>? userData;
  bool loading = true;

  List enrolledCourses = [];
  bool isVIP = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      enrolledCourses = (data['enrolledCourses'] is List)
          ? List.from(data['enrolledCourses'])
          : [];

      isVIP = data['isVIP'] == true;
      isAdmin = data['isAdmin'] == true;

      userData = Map<String, dynamic>.from(data);

      if (mounted) setState(() => loading = false);

    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "🎓 Dashboard",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.gold),
            onPressed: () {
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentProfilePage(),
                ),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: AppColors.premiumCard,
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.gold, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (userData?['name'] ?? "Student").toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVIP)
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _cardButton("كورساتي", Icons.menu_book, () {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoursesPage(),
                    ),
                  );
                }),
                _cardButton("الدفع", Icons.payment, () {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentPage(),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              "📚 كورساتي",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (enrolledCourses.isEmpty)
              const Text(
                "لا يوجد كورسات",
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enrolledCourses.length,
                itemBuilder: (context, index) {

                  final dynamic rawId = enrolledCourses[index];
                  final String courseId = rawId?.toString() ?? "";

                  if (courseId.isEmpty) {
                    return const SizedBox();
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseService.firestore
                        .collection(AppConstants.courses)
                        .doc(courseId)
                        .get(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox();
                      }

                      final raw = snapshot.data!.data();
                      final Map<String, dynamic> data =
                          raw is Map<String, dynamic>
                              ? raw
                              : (raw is Map
                                  ? raw.map((k, v) => MapEntry(k.toString(), v))
                                  : {});

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: AppColors.premiumCard,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          title: Text(
                            (data['title'] ?? "Course").toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: AppColors.gold, size: 14),
                          onTap: () {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailsPage(
                                  title: (data['title'] ?? "").toString(),
                                  courseId: courseId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: AppColors.premiumCard,
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isVIP ? "⭐ مفعل" : "❌ غير مفعل",
                      style: TextStyle(
                        color: isVIP ? Colors.green : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!isVIP)
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        style: AppColors.goldButton,
                        onPressed: () {
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentPage(),
                            ),
                          );
                        },
                        child: const Text("اشترك", style: TextStyle(fontSize: 12)),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardButton(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: AppColors.premiumCard,
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}