// 🔥 STUDENT DASHBOARD PRO MAX

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 CORE
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

// 🔥 PAGES
import '../courses_page.dart';
import '../student_profile_page.dart';
import '../course_details_page.dart';
import '../payment/payment_page.dart';

// 🔥 WIDGETS
import '../widgets/loading_widget.dart';

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
      if (user == null) return;

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      enrolledCourses = data['enrolledCourses'] ?? [];
      isVIP = data['isVIP'] ?? false;
      isAdmin = data['isAdmin'] ?? false;

      userData = data;

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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(15),
              decoration: AppColors.premiumCard,
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.gold, size: 35),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userData?['name'] ?? "Student",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVIP)
                    const Icon(Icons.star, color: Colors.amber),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _cardButton("كورساتي", Icons.menu_book, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoursesPage(),
                    ),
                  );
                }),
                _cardButton("الدفع", Icons.payment, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentPage(),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "📚 كورساتي",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

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

                  String courseId = enrolledCourses[index];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseService.firestore
                        .collection(AppConstants.courses)
                        .doc(courseId)
                        .get(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      var data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppColors.premiumCard,
                        child: ListTile(
                          title: Text(
                            data['title'] ?? "Course",
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: AppColors.gold, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailsPage(
                                  title: data['title'] ?? "",
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

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: AppColors.premiumCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "💰 الاشتراك",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isVIP ? "⭐ مفعل" : "❌ غير مفعل",
                    style: TextStyle(
                      color: isVIP ? Colors.green : Colors.red,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (!isVIP)
                    ElevatedButton(
                      style: AppColors.goldButton,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentPage(),
                          ),
                        );
                      },
                      child: const Text("اشترك الآن"),
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
          padding: const EdgeInsets.all(15),
          decoration: AppColors.premiumCard,
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}