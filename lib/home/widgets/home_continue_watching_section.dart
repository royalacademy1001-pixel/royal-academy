import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../features/courses/widgets/course_card.dart';

class HomeContinueWatchingSection extends StatelessWidget {
  const HomeContinueWatchingSection({super.key});

  static Map<String, dynamic>? _cachedCourse;
  static String _cachedCourseId = "";
  static DateTime? _lastFetchTime;

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

    final now = DateTime.now();
    final useCache = _cachedCourse != null &&
        _cachedCourseId.isNotEmpty &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < 60;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseService.firestore
          .collection("app_settings")
          .doc("home_sections")
          .get(),
      builder: (context, configSnap) {
        if (configSnap.hasData &&
            configSnap.data != null &&
            configSnap.data!.data() != null) {
          final config = configSnap.data!.data()!;
          final sections = config['sections'];

          if (sections is List) {
            final found = sections.where((e) {
              if (e is Map<String, dynamic>) {
                return e['id'] == "continue";
              }
              return false;
            }).toList();

            if (found.isNotEmpty) {
              final item = found.first as Map<String, dynamic>;
              if ((item['enabled'] ?? true) == false) {
                return const SizedBox();
              }
            }
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: useCache
              ? null
              : FirebaseService.firestore
                  .collection(AppConstants.lastWatch)
                  .where('userId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
          builder: (context, snapshot) {
            final docs = useCache
                ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
                : (snapshot.hasData && snapshot.data != null
                    ? snapshot.data!.docs
                    : <QueryDocumentSnapshot<Map<String, dynamic>>>[]);

            if (!useCache &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }

            String courseId = "";

            if (useCache) {
              courseId = _cachedCourseId;
            } else {
              if (docs.isEmpty) {
                return const SizedBox();
              }
              courseId =
                  (docs.first.data()['courseId'] ?? "").toString();
            }

            if (courseId.isEmpty) return const SizedBox();

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: useCache
                  ? null
                  : FirebaseService.firestore
                      .collection(AppConstants.courses)
                      .doc(courseId)
                      .get(),
              builder: (context, snap) {
                Map<String, dynamic>? data;

                if (useCache) {
                  data = _cachedCourse;
                } else {
                  if (snap.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  if (!snap.hasData ||
                      snap.data == null ||
                      !snap.data!.exists) {
                    return const SizedBox();
                  }

                  data = snap.data!.data();
                }

                if (data == null || data.isEmpty) {
                  return const SizedBox();
                }

                if (!_isVisibleCourse(data)) {
                  return const SizedBox();
                }

                if (!useCache) {
                  _cachedCourse = data;
                  _cachedCourseId = courseId;
                  _lastFetchTime = DateTime.now();
                }

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
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color:
                                  AppColors.gold.withValues(alpha: 0.05),
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
      },
    );
  }
}