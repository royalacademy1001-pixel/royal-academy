// 🔥 FINAL PRO MAX EDIT STUDENT PAGE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class EditStudentPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const EditStudentPage({
    super.key,
    required this.userId,
    required this.data,
  });

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {

  List enrolled = [];
  List unlocked = [];

  bool loading = false;
  String search = "";

  String? studentId;

  @override
  void initState() {
    super.initState();

    enrolled = widget.data['enrolledCourses'] ?? [];
    unlocked = widget.data['unlockedCourses'] ?? [];

    studentId = widget.data['studentId'];

    _initStudent();
  }

  Future<void> _initStudent() async {

    try {

      if (studentId != null) return;

      final doc = await FirebaseService.firestore
          .collection("students")
          .add({
        "name": widget.data['name'] ?? "",
        "phone": widget.data['phone'] ?? "",
        "linkedUserId": widget.userId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      studentId = doc.id;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(widget.userId)
          .set({
        "studentId": studentId,
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint("Student Init Error: $e");
    }
  }

  Future updateCourse(String courseId, String type, bool add) async {
    setState(() => loading = true);

    try {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(widget.userId)
          .update({
        type: add
            ? FieldValue.arrayUnion([courseId])
            : FieldValue.arrayRemove([courseId])
      });

      if (studentId != null) {
        await FirebaseService.firestore
            .collection("students")
            .doc(studentId)
            .set({
          type: add
              ? FieldValue.arrayUnion([courseId])
              : FieldValue.arrayRemove([courseId])
        }, SetOptions(merge: true));
      }

      setState(() {
        if (type == "enrolledCourses") {
          add ? enrolled.add(courseId) : enrolled.remove(courseId);
        } else {
          add ? unlocked.add(courseId) : unlocked.remove(courseId);
        }
      });

      show(add ? "تم التعديل ✅" : "تم الحذف ❌");

    } catch (_) {
      show("حصل خطأ ❌");
    }

    setState(() => loading = false);
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "👤 إدارة الطالب",
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Stack(
        children: [

          Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "🔍 ابحث عن كورس...",
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => search = val),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore
                      .collection(AppConstants.courses)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.gold),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          "❌ خطأ في تحميل الكورسات",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 10),
                            const Text(
                              "لا يوجد كورسات",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    var courses = snapshot.data!.docs;

                    var filtered = courses.where((c) {
                      var data =
                          c.data() as Map<String, dynamic>;

                      String title =
                          (data['title'] ?? "")
                              .toLowerCase();

                      return search.isEmpty ||
                          title.contains(search.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 10),
                            const Text(
                              "لا يوجد كورسات",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: filtered.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {

                        var c = filtered[index];
                        var data =
                            c.data() as Map<String, dynamic>;

                        bool isEnrolled = enrolled.contains(c.id);
                        bool isUnlocked = unlocked.contains(c.id);

                        String image =
                            (data['image'] ?? "").toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.gold.withValues(alpha: 0.1),
                              ),
                              child: image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppColors.gold),
                                      ),
                                    )
                                  : const Icon(Icons.school, color: AppColors.gold),
                            ),

                            title: Text(
                              data['title'] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                isEnrolled
                                    ? "📚 مشترك في المسار"
                                    : isUnlocked
                                        ? "🔓 تم فتح المحتوى"
                                        : "❌ غير مسجل",
                                style: TextStyle(
                                    color: isEnrolled ? Colors.green : isUnlocked ? Colors.orange : Colors.grey,
                                    fontSize: 12),
                              ),
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                _actionIcon(
                                  icon: isEnrolled ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: isEnrolled ? Colors.green : Colors.grey,
                                  onTap: () => updateCourse(c.id, "enrolledCourses", !isEnrolled),
                                ),

                                const SizedBox(width: 8),

                                _actionIcon(
                                  icon: isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                  color: isUnlocked ? Colors.orange : Colors.grey,
                                  onTap: () => updateCourse(c.id, "unlockedCourses", !isUnlocked),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          if (loading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}