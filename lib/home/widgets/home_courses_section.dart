import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '/core/constants.dart';
import '../../core/firebase_service.dart';
import '../../features/courses/widgets/course_card.dart';

class HomeCoursesSection extends StatelessWidget {
  const HomeCoursesSection({super.key});

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.trending_up_rounded,
                color: AppColors.gold, size: 18),
          ],
        ),
      );

  bool _isVisibleCourse(Map<String, dynamic> data) {
    final approved = data['approved'] == true;
    final status = (data['status'] ?? "").toString().toLowerCase();
    return approved || status == "approved";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.firestore
            .collection(AppConstants.courses)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox();
          }

          final rawDocs = snapshot.data!.docs;

          if (rawDocs.isEmpty) {
            return const Center(
              child: Text(
                "🚫 لا يوجد كورسات حالياً",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final courses = rawDocs.where((doc) {
            final data = doc.data();
            if (data == null) return false;
            return _isVisibleCourse(data);
          }).toList();

          if (courses.isEmpty) {
            return const Center(
              child: Text(
                "🚫 لا يوجد كورسات حالياً",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("🔥 الأكثر مشاهدة"),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final data = course.data();
                    if (data == null) return const SizedBox();

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 235,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: CourseCard(
                          id: course.id,
                          data: data,
                          doneLessons: 0,
                          hasAccess: true,
                        ),
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