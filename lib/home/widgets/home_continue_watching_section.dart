import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../features/courses/widgets/course_card.dart';

class HomeContinueWatchingSection extends StatelessWidget {
  const HomeContinueWatchingSection({super.key});

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
            const Icon(Icons.play_circle_fill_rounded,
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
    final user = FirebaseService.auth.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.firestore
          .collection(AppConstants.lastWatch)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const SizedBox();
        }

        final courseId = (docs.first.data()['courseId'] ?? "").toString();
        if (courseId.isEmpty) return const SizedBox();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseService.firestore
              .collection(AppConstants.courses)
              .doc(courseId)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }

            if (!snap.hasData || snap.data == null || !snap.data!.exists) {
              return const SizedBox();
            }

            final data = snap.data!.data();
            if (data == null) return const SizedBox();

            if (!_isVisibleCourse(data)) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title("⏯ أكمل المشاهدة"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
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
                        id: courseId,
                        data: data,
                        doneLessons: 0,
                        hasAccess: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}