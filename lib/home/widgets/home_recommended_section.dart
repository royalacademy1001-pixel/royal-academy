import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../features/courses/widgets/course_card.dart';

class HomeRecommendedSection extends StatelessWidget {
  const HomeRecommendedSection({super.key});

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedCourses = [];
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
            const Icon(Icons.auto_awesome_rounded,
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
    final now = DateTime.now();
    final useCache = _cachedCourses.isNotEmpty &&
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
                return e['id'] == "recommended";
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("⭐ مقترح لك"),
            SizedBox(
              height: 320,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: useCache
                    ? null
                    : FirebaseService.firestore
                        .collection(AppConstants.courses)
                        .orderBy("createdAt", descending: true)
                        .limit(6)
                        .snapshots(),
                builder: (context, snapshot) {
                  final rawDocs = useCache
                      ? _cachedCourses
                      : (snapshot.hasData && snapshot.data != null
                          ? snapshot.data!.docs
                          : <QueryDocumentSnapshot<Map<String, dynamic>>>[]);

                  if (!useCache &&
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  if (rawDocs.isEmpty) {
                    return const SizedBox();
                  }

                  final docs = rawDocs.where((doc) {
                    final data = doc.data();
                    if (data == null) return false;
                    return _isVisibleCourse(data);
                  }).toList();

                  if (!useCache && docs.isNotEmpty) {
                    _cachedCourses = docs;
                    _lastFetchTime = DateTime.now();
                  }

                  if (docs.isEmpty) {
                    return const SizedBox();
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
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
                            id: doc.id,
                            data: data,
                            doneLessons: 0,
                            hasAccess: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}