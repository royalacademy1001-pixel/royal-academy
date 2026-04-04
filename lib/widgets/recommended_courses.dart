// 🔥 RECOMMENDED COURSES (PRO MAX++ AI READY)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../course_details_page.dart';

class RecommendedCourses extends StatelessWidget {
  final String userId;

  const RecommendedCourses({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<QuerySnapshot>(

      /// 🔥 STEP 1: user activity
      future: FirebaseService.firestore
          .collection(AppConstants.progress)
          .where('userId', isEqualTo: userId)
          .get(),

      builder: (context, progressSnap) {

        if (!progressSnap.hasData) {
          return const SizedBox();
        }

        /// 🧠 collect courseIds
        Set<String> userCourses = {};

        for (var doc in progressSnap.data!.docs) {
          var d = doc.data() as Map<String, dynamic>;
          if (d['courseId'] != null) {
            userCourses.add(d['courseId']);
          }
        }

        if (userCourses.isEmpty) {
          return const SizedBox();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.firestore
              .collection(AppConstants.courses)
              .snapshots(),

          builder: (context, courseSnap) {

            if (!courseSnap.hasData) {
              return const SizedBox();
            }

            List docs = courseSnap.data!.docs;

            /// 🔥 FILTER SMART
            List recommended = docs.where((c) {

              var data = c.data() as Map<String, dynamic>;

              /// exclude already watched
              if (userCourses.contains(c.id)) return false;

              /// 🔥 same category logic
              String cat = data['categoryId'] ?? "";

              return userCourses.any((courseId) {
                var matched = docs.firstWhere(
                    (e) => e.id == courseId,
                    orElse: () => null);

                if (matched == null) return false;

                var mData =
                    matched.data() as Map<String, dynamic>;

                return mData['categoryId'] == cat;
              });

            }).toList();

            if (recommended.isEmpty) {
              return const SizedBox();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "🎯 مقترح لك",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommended.length,
                    itemBuilder: (context, i) {

                      var c = recommended[i];
                      var data =
                          c.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailsPage(
                                title: data['title'] ?? "",
                                courseId: c.id,
                              ),
                            ),
                          );
                        },

                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [

                              Expanded(
                                child: Image.network(
                                  data['image'] ??
                                      AppConstants.defaultImage,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.all(10),
                                child: Text(
                                  data['title'] ?? "",
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }
}