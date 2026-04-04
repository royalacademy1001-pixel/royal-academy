import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

class PickLessonPage extends StatefulWidget {
  const PickLessonPage({super.key});

  @override
  State<PickLessonPage> createState() => _PickLessonPageState();
}

class _PickLessonPageState extends State<PickLessonPage> {

  String? selectedCourseId;
  List<QueryDocumentSnapshot> courses = [];
  List<QueryDocumentSnapshot> lessons = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    final snap = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .get();

    if (mounted) {
      setState(() {
        courses = snap.docs;
        loading = false;
      });
    }
  }

  Future<void> loadLessons(String courseId) async {
    final snap = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(courseId)
        .collection(AppConstants.lessons)
        .get();

    if (mounted) {
      setState(() {
        lessons = snap.docs;
        selectedCourseId = courseId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          selectedCourseId == null ? "اختار الكورس" : "اختار الدرس",
          style: const TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : selectedCourseId == null
              ? ListView(
                  children: courses.map((c) {
                    return ListTile(
                      title: Text(
                        c['title'] ?? "Course",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => loadLessons(c.id),
                    );
                  }).toList(),
                )
              : ListView(
                  children: lessons.map((l) {
                    return ListTile(
                      title: Text(
                        l['title'] ?? "Lesson",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context, l.id);
                      },
                    );
                  }).toList(),
                ),
    );
  }
}