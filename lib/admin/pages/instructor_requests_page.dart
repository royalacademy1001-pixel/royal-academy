// 🔥 INSTRUCTOR REQUESTS (FINAL SAFE PRO MAX)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class InstructorRequestsPage extends StatefulWidget {
  const InstructorRequestsPage({super.key});

  @override
  State<InstructorRequestsPage> createState() => _InstructorRequestsPageState();
}

class _InstructorRequestsPageState extends State<InstructorRequestsPage> {
  bool loadingAction = false;

  final rejectController = TextEditingController();

  void show(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<bool> confirm(String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<String?> getRejectReason() async {
    rejectController.clear();

    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("سبب الرفض", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: rejectController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "اكتب السبب",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, rejectController.text.trim()),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  Future<String?> pickCourse() async {
    final ctx = context;

    var snap = await FirebaseService.firestore
        .collection("courses")
        .where("status", isEqualTo: "approved")
        .get();

    if (!context.mounted) return null; // ✅ الحل الحقيقي

    return await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text(
          "اختار الكورس",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: snap.docs.map((c) {
              return ListTile(
                title: Text(
                  c['title'] ?? "Course",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogCtx, c.id);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future runAction(Future Function() action) async {
    if (loadingAction) return;

    setState(() => loadingAction = true);

    try {
      await action();
    } catch (e) {
      debugPrint("Instructor Error: $e");
      show("حصل خطأ ❌", color: Colors.red);
    }

    if (mounted) {
      setState(() => loadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("📩 طلبات المدرسين",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection("instructor_requests")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text("خطأ ❌", style: TextStyle(color: Colors.red)),
                );
              }

              final requests = snapshot.data?.docs ?? [];

              if (requests.isEmpty) {
                return const Center(
                  child: Text("لا يوجد طلبات",
                      style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  var doc = requests[index];
                  var data = doc.data() as Map<String, dynamic>? ?? {};

                  String email = data['email'] ?? "بدون بيانات";
                  String userId = data['userId'] ?? "";

                  String title = data['title'] ?? "بدون عنوان";
                  String instructorId = userId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: AppColors.premiumCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 5),
                        Text(email,
                            style: const TextStyle(
                              color: Colors.white70,
                            )),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  if (loadingAction) return;

                                  bool ok =
                                      await confirm("اختار الكورس للمدرس");
                                  if (!ok) return;

                                  String? courseId = await pickCourse();
                                  if (courseId == null) return;

                                  await runAction(() async {
                                    await FirebaseService.firestore
                                        .collection("users")
                                        .doc(instructorId)
                                        .set({
                                      "isInstructor": true,
                                      "instructorApproved": true,
                                      "instructorRequest": false,
                                      "teachingCourses":
                                          FieldValue.arrayUnion([courseId])
                                    }, SetOptions(merge: true));

                                    await doc.reference.delete();

                                    show("تم قبول المدرس وربطه بالكورس ✅🔥");
                                  });
                                },
                                child: const Text("قبول"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  if (loadingAction) return;

                                  String? reason = await getRejectReason();
                                  if (reason == null) return;

                                  await runAction(() async {
                                    await FirebaseService.firestore
                                        .collection("users")
                                        .doc(instructorId)
                                        .set({
                                      "isInstructor": false,
                                      "instructorApproved": false,
                                      "instructorRequest": false,
                                    }, SetOptions(merge: true));

                                    await doc.reference.delete();

                                    show("تم الرفض ❌", color: Colors.red);
                                  });
                                },
                                child: const Text("رفض"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: AppColors.goldButton,
                          onPressed: () {},
                          child: const Text("عرض"),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (loadingAction)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
