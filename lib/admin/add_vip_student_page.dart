import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/colors.dart';
import '../core/firebase_service.dart';
import '../shared/models/vip_student_model.dart';
import '../shared/services/vip_student_service.dart';

class AddVipStudentPage extends StatefulWidget {
  const AddVipStudentPage({super.key});

  @override
  State<AddVipStudentPage> createState() => _AddVipStudentPageState();
}

class _AddVipStudentPageState extends State<AddVipStudentPage> {
  final name = TextEditingController();
  final phone = TextEditingController();

  bool loading = false;

  String? selectedCourseId;
  bool isVIP = true;

  Future<void> save() async {
    if (loading) return;

    if (name.text.trim().isEmpty) {
      showSnack("اكتب الاسم ❗");
      return;
    }

    if (phone.text.trim().isEmpty) {
      showSnack("اكتب رقم الموبايل ❗");
      return;
    }

    if (selectedCourseId == null) {
      showSnack("اختار كورس ❗");
      return;
    }

    setState(() => loading = true);

    try {
      final student = VipStudentModel(
        id: "",
        name: name.text.trim(),
        phone: phone.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await VipStudentService.addStudent(student);

      final doc = FirebaseService.firestore.collection("users").doc();

      await doc.set({
        "name": name.text.trim(),
        "phone": phone.text.trim(),
        "email": "",
        "isAdmin": false,
        "isVIP": isVIP,
        "blocked": false,
        "instructorApproved": false,
        "enrolledCourses": [selectedCourseId],
        "unlockedCourses": [selectedCourseId],
        "createdAt": FieldValue.serverTimestamp(),
        "createdByAdmin": true,
      });

      if (!mounted) return;

      showSnack("تم إضافة الطالب بنجاح ✅");

      name.clear();
      phone.clear();

      setState(() {
        selectedCourseId = null;
        isVIP = true;
      });

    } catch (e) {
      showSnack("خطأ ❌ $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Widget _buildCoursesDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection("courses")
          .where("approved", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: AppColors.gold);
        }

        final courses = snapshot.data!.docs;

        if (courses.isEmpty) {
          return const Text(
            "لا توجد كورسات",
            style: TextStyle(color: Colors.white),
          );
        }

        return DropdownButtonFormField<String>(
          value: selectedCourseId,
          dropdownColor: AppColors.black,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "اختار الكورس",
          ),
          items: courses.map((c) {
            final data = c.data() as Map<String, dynamic>;

            return DropdownMenuItem(
              value: c.id,
              child: Text(
                (data['title'] ?? "").toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => selectedCourseId = v);
          },
        );
      },
    );
  }

  void showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        content: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إضافة طالب"),
        backgroundColor: AppColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "الاسم"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "الموبايل"),
            ),

            const SizedBox(height: 20),

            _buildCoursesDropdown(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "VIP",
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  value: isVIP,
                  onChanged: (v) {
                    setState(() => isVIP = v);
                  },
                )
              ],
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator(color: AppColors.gold)
                : ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                    ),
                    child: const Text(
                      "حفظ",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}