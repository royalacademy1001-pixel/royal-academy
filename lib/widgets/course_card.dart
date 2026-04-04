import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/colors.dart';
import '../course_details_page.dart';
import 'press_effect.dart';
import '../core/firebase_service.dart';

class CourseCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final int doneLessons;
  final bool hasAccess;

  const CourseCard({
    super.key,
    required this.id,
    required this.data,
    required this.doneLessons,
    required this.hasAccess,
  });

  @override
  Widget build(BuildContext context) {
    String image = FirebaseService.fixImage(data['image'] ?? "");
    double rating = (data['rating'] ?? 4.5).toDouble();
    int total = data['lessonsCount'] ?? 0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.progress)
          .where('userId',
              isEqualTo: FirebaseService.auth.currentUser?.uid ?? "")
          .where('courseId', isEqualTo: id)
          .snapshots(),
      builder: (context, snapshot) {
        int done = doneLessons;

        if (snapshot.hasData) {
          done = snapshot.data!.docs.length;
        }

        double progress =
            total == 0 ? 0 : (done / total).clamp(0, 1);

        return PressEffect(
          onTap: () {
            debugPrint("CLICK WORKING ✅");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailsPage(
                  title: data['title'] ?? "",
                  courseId: id,
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                ...AppColors.goldShadow,
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                      color: Colors.black,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.white),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black,
                                    child: const Icon(Icons.image,
                                        color: Colors.white),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.85),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          if (!hasAccess)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.lock, color: Colors.red),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: AppColors.premiumCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? "Course",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "$total درس",
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                color: AppColors.gold,
                                backgroundColor: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "أكملت ${(progress * 100).toInt()}%",
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 9,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: ElevatedButton(
                                style: AppColors.goldButton,
                                onPressed: () {
                                  debugPrint("BUTTON CLICK ✅");

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailsPage(
                                        title: data['title'] ?? "",
                                        courseId: id,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  progress > 0 ? "استكمال" : "ابدأ الآن",
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}