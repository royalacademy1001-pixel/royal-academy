// 🔥 INSTRUCTOR DASHBOARD (FINAL FIXED VERSION)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Core
import '../core/firebase_service.dart';
import '../core/colors.dart';

// 🔥 FIXED PATH
import '../admin/add_course_page.dart';
import '../course_details_page.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<InstructorDashboardPage> createState() =>
      _InstructorDashboardPageState();
}

class _InstructorDashboardPageState
    extends State<InstructorDashboardPage> {

  String userId = "";

  bool isInstructor = false;
  bool checking = true;

  int totalStudents = 0;
  int totalCourses = 0;
  int totalRevenue = 0;

  List teachingCourses = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseService.auth.currentUser?.uid ?? "";
    checkInstructor();
  }

  Future<void> checkInstructor() async {
    try {
      if (userId.isEmpty) return;

      var doc = await FirebaseService.firestore
          .collection("users")
          .doc(userId)
          .get();

      var data = doc.data() ?? {};

      isInstructor = data['instructorApproved'] == true;
      teachingCourses = data['teachingCourses'] ?? [];

    } catch (_) {}

    if (mounted) {
      setState(() => checking = false);
    }
  }

  void calculateStats(List<QueryDocumentSnapshot> courses) {

    int students = 0;
    int revenue = 0;

    for (var c in courses) {
      var d = c.data() as Map<String, dynamic>;

      int s = d['students'] ?? 0;
      int p = d['price'] ?? 0;

      students += s;
      revenue += (s * p);
    }

    totalStudents = students;
    totalCourses = courses.length;
    totalRevenue = revenue;
  }

  @override
  Widget build(BuildContext context) {

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    if (checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
          ),
        ),
      );
    }

    if (!isInstructor) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "👨‍🏫 لوحة المدرس",
            style: TextStyle(color: AppColors.gold),
          ),
          backgroundColor: AppColors.black,
        ),
        body: const Center(
          child: Text(
            "🚫 غير مصرح لك بالدخول",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "👨‍🏫 لوحة المدرس",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCoursePage(),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("courses")
            .where(FieldPath.documentId, whereIn: teachingCourses.isEmpty ? ["__none__"] : teachingCourses)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            );
          }

          final courses = snapshot.data!.docs;

          calculateStats(courses);

          if (courses.isEmpty) {
            return const Center(
              child: Text(
                "🚫 لا يوجد كورسات حتى الآن",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [

              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(15),
                decoration: AppColors.premiumCard,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [

                    Column(
                      children: [
                        const Text("📚",
                            style: TextStyle(fontSize: 20)),
                        Text("$totalCourses",
                            style: const TextStyle(
                                color: Colors.white)),
                        const Text("كورسات",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),

                    Column(
                      children: [
                        const Text("👥",
                            style: TextStyle(fontSize: 20)),
                        Text("$totalStudents",
                            style: const TextStyle(
                                color: Colors.white)),
                        const Text("طلاب",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),

                    Column(
                      children: [
                        const Text("💰",
                            style: TextStyle(fontSize: 20)),
                        Text("$totalRevenue",
                            style: const TextStyle(
                                color: AppColors.gold)),
                        const Text("جنيه",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {

                    var doc = courses[index];

                    var data =
                        doc.data() as Map<String, dynamic>? ?? {};

                    String title = data['title'] ?? "بدون عنوان";
                    int students = data['students'] ?? 0;
                    int price = data['price'] ?? 0;

                    String status = (data['status'] ?? "pending").toString();
                    String rejectReason = (data['rejectReason'] ?? "").toString();

                    Color statusColor = status == "approved"
                        ? Colors.green
                        : status == "rejected"
                            ? Colors.red
                            : Colors.orange;

                    String statusText = status == "approved"
                        ? "تمت الموافقة"
                        : status == "rejected"
                            ? "مرفوض"
                            : "قيد المراجعة";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: AppColors.premiumCard,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              const Icon(Icons.people,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 5),

                              Text(
                                "$students طالب",
                                style: const TextStyle(color: Colors.white),
                              ),

                              const Spacer(),

                              Text(
                                price == 0
                                    ? "مجاني"
                                    : "$price جنيه",
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),

                          if (status == "rejected" && rejectReason.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "سبب الرفض: $rejectReason",
                                style: const TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: AppColors.goldButton,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailsPage(
                                      title: title,
                                      courseId: doc.id,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("عرض الكورس"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}