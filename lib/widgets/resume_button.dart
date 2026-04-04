import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../video_page.dart';
import '../core/colors.dart';

class ResumeButton extends StatefulWidget {
  final QuerySnapshot? lastSnap;
  final String? lessonId;
  final String? courseId;
  final bool hasAccess;

  const ResumeButton({
    super.key,
    this.lastSnap,
    this.lessonId,
    this.courseId,
    this.hasAccess = true,
  });

  @override
  State<ResumeButton> createState() => _ResumeButtonState();
}

class _ResumeButtonState extends State<ResumeButton>
    with SingleTickerProviderStateMixin {
  bool loading = false;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scale = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get hasResumeData {
    return (widget.lastSnap != null && widget.lastSnap!.docs.isNotEmpty) ||
        (widget.lessonId != null && widget.courseId != null);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasResumeData) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ScaleTransition(
        scale: _scale,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 8,
          ),
          onPressed: loading ? null : _resume,
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "كمل من حيث توقفت",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _resume() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      String? courseId;
      String? lessonId;

      if (widget.lastSnap != null && widget.lastSnap!.docs.isNotEmpty) {
        var last = widget.lastSnap!.docs.first;
        courseId = last['courseId'];
        lessonId = last['lessonId'];
      } else {
        courseId = widget.courseId;
        lessonId = widget.lessonId;
      }

      if (courseId == null || lessonId == null) {
        _showError("بيانات غير صحيحة ❌");
        return;
      }

      var lessonDoc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(courseId)
          .collection(AppConstants.lessons)
          .doc(lessonId)
          .get();

      if (!lessonDoc.exists) {
        _showError("الدرس غير موجود ❌");
        return;
      }

      var data = lessonDoc.data();

      if (data == null) {
        _showError("بيانات غير متوفرة ❌");
        return;
      }

      final bool lessonIsFree = data['isFree'] == true;
      final bool canOpenLesson = widget.hasAccess || lessonIsFree;

      if (!canOpenLesson) {
        Navigator.pushNamed(context, "/payment");
        return;
      }

      String url = (data['contentUrl'] ?? data['video'] ?? "").toString();

      if (url.isEmpty) {
        _showError("المحتوى غير متوفر ❌");
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPage(
            title: (data['title'] ?? "").toString(),
            videoUrl: url,
            courseId: courseId!,
            lessonId: lessonId!,
            isFree: lessonIsFree,
          ),
        ),
      );
    } catch (_) {
      _showError("حدث خطأ ❌");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}