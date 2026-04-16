import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '/core/constants.dart';
import '../../core/firebase_service.dart';
import '../../features/courses/widgets/course_card.dart';

class HomeCoursesSection extends StatefulWidget {
  const HomeCoursesSection({super.key});

  @override
  State<HomeCoursesSection> createState() => _HomeCoursesSectionState();
}

class _HomeCoursesSectionState extends State<HomeCoursesSection> {
  final ScrollController _scrollController = ScrollController();

  int focusedIndex = 0;

  bool _didPreload = false;
  double _itemExtent = 247.0;

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

  Widget _loadingCard(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  void _preloadImages(List<QueryDocumentSnapshot<Map<String, dynamic>>> courses) {
    for (final c in courses) {
      final data = c.data();
      final raw = (data['image'] ?? "").toString().trim();
      if (raw.isEmpty || (!raw.startsWith("http") && !raw.startsWith("gs://"))) {
        continue;
      }

      final dynamic versionValue =
          data['imageUpdatedAt'] ?? data['updatedAt'] ?? data['modifiedAt'];

      String version = "";
      if (versionValue is Timestamp) {
        version = versionValue.millisecondsSinceEpoch.toString();
      } else if (versionValue != null) {
        version = versionValue.toString().trim();
      }

      FirebaseService.resolveImageUrl(raw, version: version);
    }
  }

  double _calculateScale(int index) {
    if (!_scrollController.hasClients) return 1;

    final position = _scrollController.offset / _itemExtent;
    final diff = (index - position).abs();
    final scale = 1 - (diff * 0.08);
    return scale.clamp(0.88, 1.05);
  }

  double _calculateOpacity(int index) {
    if (!_scrollController.hasClients) return 1;

    final position = _scrollController.offset / _itemExtent;
    final diff = (index - position).abs();
    return (1 - (diff * 0.3)).clamp(0.6, 1.0);
  }

  void _updateFocus() {
    if (!_scrollController.hasClients) return;
    final index = (_scrollController.offset / _itemExtent).round();
    if (index != focusedIndex && mounted) {
      setState(() {
        focusedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFocus);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFocus);
    _scrollController.dispose();
    super.dispose();
  }

  void _snapToItem() {
    if (!_scrollController.hasClients) return;
    final maxIndex = (_scrollController.position.maxScrollExtent / _itemExtent).round();
    final safeIndex = focusedIndex.clamp(0, maxIndex);
    final target = safeIndex * _itemExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final cardWidth = isWide ? 275.0 : 235.0;
          final cardHeight = isWide ? 300.0 : 278.0;
          _itemExtent = cardWidth + 12;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.firestore
                .collection(AppConstants.courses)
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              final rawDocs = snapshot.hasData && snapshot.data != null
                  ? snapshot.data!.docs
                  : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              final courses = rawDocs.where((doc) {
                final data = doc.data();
                if (data.isEmpty) return false;
                return _isVisibleCourse(data);
              }).toList().cast<QueryDocumentSnapshot<Map<String, dynamic>>>();

              if (courses.isNotEmpty && !_didPreload) {
                _didPreload = true;
                _preloadImages(courses);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("🔥 الأكثر مشاهدة"),
                  Expanded(
                    child: isLoading
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            physics: const BouncingScrollPhysics(),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return _loadingCard(cardWidth, cardHeight);
                            },
                          )
                        : courses.isEmpty
                            ? const Center(
                                child: Text(
                                  "🚫 لا يوجد كورسات حالياً",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : NotificationListener<ScrollEndNotification>(
                                onNotification: (_) {
                                  if (mounted) _snapToItem();
                                  return false;
                                },
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (_) {
                                    if (mounted) setState(() {});
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: courses.length,
                                    itemBuilder: (context, index) {
                                      final course = courses[index];
                                      final data = course.data();

                                      if (data.isEmpty) {
                                        return const SizedBox();
                                      }

                                      final scale = _calculateScale(index);
                                      final opacity = _calculateOpacity(index);
                                      final isFocused = index == focusedIndex;

                                      return RepaintBoundary(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 200),
                                          opacity: opacity,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 220),
                                            curve: Curves.easeOutCubic,
                                            transform: Matrix4.identity()
                                              ..scale(scale)
                                              ..translate(0.0,
                                                  (1 - scale) * (isFocused ? 10 : 25)),
                                            width: cardWidth,
                                            height: cardHeight,
                                            margin: const EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(22),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.4),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 10),
                                                ),
                                                BoxShadow(
                                                  color: AppColors.gold.withValues(
                                                      alpha: isFocused ? 0.18 : 0.05),
                                                  blurRadius: isFocused ? 26 : 14,
                                                  spreadRadius: isFocused ? 2 : 0,
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
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}