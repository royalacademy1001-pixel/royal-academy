import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/colors.dart';
import '../../../course_details_page.dart';
import '../../../core/firebase_service.dart';
import 'course_card_content.dart';

class CourseCard extends StatefulWidget {
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
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  late Future<String> _imageFuture;

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

  double _progressValue(int done, int total) {
    if (total <= 0) return 0;
    final value = done / total;
    if (!value.isFinite) return 0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  String _imageVersion(Map<String, dynamic> data) {
    final dynamic versionValue =
        data['imageUpdatedAt'] ?? data['updatedAt'] ?? data['modifiedAt'];

    if (versionValue is Timestamp) {
      return versionValue.millisecondsSinceEpoch.toString();
    }

    if (versionValue != null) {
      final text = versionValue.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return "";
  }

  String _imageSignature(Map<String, dynamic> data) {
    return '${data['image'] ?? ''}|${data['imageUpdatedAt'] ?? ''}|${data['updatedAt'] ?? ''}|${data['modifiedAt'] ?? ''}';
  }

  Future<String> _resolveImageUrl() async {
    final String raw = _text(widget.data['image']);
    if (raw.isEmpty) return "";

    final version = _imageVersion(widget.data);
    final resolved = await FirebaseService.resolveImageUrl(
      raw,
      version: version,
      forceRefresh: true,
    );
    final fixed = FirebaseService.fixImage(resolved, version: version);

    if (fixed.isEmpty) return "";
    if (!fixed.startsWith("http")) return "";

    return fixed;
  }

  void _openCourse(BuildContext context) {
    if (!mounted) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailsPage(
          title: _text(widget.data['title'], "Course"),
          courseId: widget.id,
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required double progress,
    required bool userHasAccess,
    required String imageUrl,
  }) {
    final rating = _double(widget.data['rating'], 4.5);
    final total = _int(widget.data['lessonsCount'], 0);
    final title = _text(widget.data['title'], "Course");
    final bool isPopular = _int(widget.data['views'], 0) > 100;

    return RepaintBoundary(
      child: CourseCardContent(
        key: ValueKey('${widget.id}_${_imageSignature(widget.data)}_$imageUrl'),
        imageUrl: imageUrl,
        rating: rating,
        totalLessons: total,
        title: title,
        progress: progress,
        hasAccess: userHasAccess,
        isPopular: isPopular,
        onOpen: () {
          debugPrint("CLICK WORKING ✅");
          if (!mounted) return;
          if (!context.mounted) return;
          _openCourse(context);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _imageFuture = Future.delayed(
      const Duration(milliseconds: 50),
      () => _resolveImageUrl(),
    );
  }

  @override
  void didUpdateWidget(covariant CourseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_imageSignature(oldWidget.data) != _imageSignature(widget.data)) {
      _imageFuture = Future.delayed(
        const Duration(milliseconds: 50),
        () => _resolveImageUrl(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int total = _int(widget.data['lessonsCount'], 0);
    final bool userHasAccess =
        FirebaseService.auth.currentUser == null ? true : widget.hasAccess == true;

    return FutureBuilder<String>(
      future: _imageFuture,
      builder: (context, imageSnapshot) {
        final String imageUrl = imageSnapshot.data ?? "";

        if (FirebaseService.auth.currentUser == null) {
          final double progress = _progressValue(widget.doneLessons, total);
          return _buildCourseCard(
            context,
            progress: progress,
            userHasAccess: true,
            imageUrl: imageUrl,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.firestore
              .collection(AppConstants.progress)
              .where('userId', isEqualTo: FirebaseService.auth.currentUser!.uid)
              .where('courseId', isEqualTo: widget.id)
              .snapshots(),
          builder: (context, snapshot) {
            int done = widget.doneLessons;

            if (snapshot.connectionState == ConnectionState.waiting) {
              done = widget.doneLessons;
            } else if (snapshot.hasData && snapshot.data != null) {
              done = snapshot.data!.docs.length;
            }

            final double progress = _progressValue(done, total);

            return _buildCourseCard(
              context,
              progress: progress,
              userHasAccess: userHasAccess,
              imageUrl: imageUrl,
            );
          },
        );
      },
    );
  }
}