import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/colors.dart';
import '../../../course_details_page.dart';
import '../../../shared/widgets/press_effect.dart';
import '../../../core/firebase_service.dart';

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

  String _text(dynamic value, [String fallback = ""]) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }

  double _double(dynamic value, [double fallback = 4.5]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? fallback;
  }

  int _int(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  void _openCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailsPage(
          title: _text(data['title'], "Course"),
          courseId: id,
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required double progress,
  }) {
    final image = FirebaseService.fixImage(_text(data['image']));
    final rating = _double(data['rating'], 4.5);
    final total = _int(data['lessonsCount'], 0);
    final title = _text(data['title'], "Course");
    final bool isPopular = _int(data['views'], 0) > 100;

    return PressEffect(
      onTap: () {
        debugPrint("CLICK WORKING ✅");
        _openCourse(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasAccess
                ? AppColors.gold.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: [
            ...AppColors.goldShadow,
            BoxShadow(
              color: hasAccess
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.black.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.black,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      if (isPopular)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "🔥 الأكثر مشاهدة",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (!hasAccess)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.lock, color: Colors.red, size: 18),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: AppColors.premiumCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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
                            minHeight: 6,
                            color: AppColors.gold,
                            backgroundColor: Colors.grey.shade900,
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
                          height: 35,
                          child: ElevatedButton(
                            style: AppColors.goldButton,
                            onPressed: () {
                              debugPrint("BUTTON CLICK ✅");
                              _openCourse(context);
                            },
                            child: Text(
                              progress > 0 ? "استكمال" : "ابدأ الآن",
                              style: const TextStyle(fontSize: 12),
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
  }

  @override
  Widget build(BuildContext context) {
    final String image = FirebaseService.fixImage(_text(data['image']));
    final double rating = _double(data['rating'], 4.5);
    final int total = _int(data['lessonsCount'], 0);
    final bool userHasAccess = FirebaseService.auth.currentUser == null
        ? true
        : hasAccess == true;

    if (FirebaseService.auth.currentUser == null) {
      final double progress = total == 0 ? 0 : (doneLessons / total).clamp(0, 1);
      return _buildCourseCard(context, progress: progress);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.progress)
          .where('userId', isEqualTo: FirebaseService.auth.currentUser!.uid)
          .where('courseId', isEqualTo: id)
          .snapshots(),
      builder: (context, snapshot) {
        int done = doneLessons;

        if (snapshot.hasData) {
          done = snapshot.data!.docs.length;
        }

        final double progress = total == 0 ? 0 : (done / total).clamp(0, 1);

        return PressEffect(
          onTap: () {
            debugPrint("CLICK WORKING ✅");
            _openCourse(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: userHasAccess
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              boxShadow: [
                ...AppColors.goldShadow,
                BoxShadow(
                  color: userHasAccess
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.black.withOpacity(0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 132,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black,
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.95),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          if (!userHasAccess)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.lock, color: Colors.red, size: 18),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: AppColors.premiumCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['title'] ?? "Course").toString(),
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
                                minHeight: 6,
                                color: AppColors.gold,
                                backgroundColor: Colors.grey.shade900,
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
                              height: 35,
                              child: ElevatedButton(
                                style: AppColors.goldButton,
                                onPressed: () {
                                  debugPrint("BUTTON CLICK ✅");
                                  _openCourse(context);
                                },
                                child: Text(
                                  progress > 0 ? "استكمال" : "ابدأ الآن",
                                  style: const TextStyle(fontSize: 12),
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