// 🔥 IMPORTS FIRST
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Core
import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

// 🔥 Widgets
import '../../widgets/loading_widget.dart';
import '../widgets/student_item.dart';
import '../widgets/courses_dialog.dart';

// 🔥 Pages
import 'edit_student_page.dart';

class StudentsManagementPage extends StatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  State<StudentsManagementPage> createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  bool loading = false;
  bool actionLock = false;

  String search = "";

  final ScrollController _scroll = ScrollController();

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future runSafe(Future Function() action) async {
    if (loading || actionLock) return;

    actionLock = true;
    setState(() => loading = true);

    try {
      await action();
    } catch (e) {
      debugPrint("Students Error: $e");
      show("حدث خطأ ❌");
    }

    if (mounted) setState(() => loading = false);
    actionLock = false;
  }

  // 🔥 حضور
  Future<void> _markAttendance(String userId) async {
    await runSafe(() async {
      await FirebaseService.firestore.collection("attendance").add({
        "userId": userId,
        "date": FieldValue.serverTimestamp(),
        "status": "present",
      });
      show("تم تسجيل الحضور ✅");
    });
  }

  // 🔥 إضافة نتيجة (متوافق مع multi select)
  Future<void> _addResult(String userId) async {
    final scoreController = TextEditingController();
    String? selectedCourseId;

    showCoursesDialog(
      context,
      userId: userId,
      unlock: false,
      onSelect: (courseIds) async {
        if (courseIds.isEmpty) return;

        selectedCourseId = courseIds.first;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text("📊 إضافة نتيجة",
                style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "ادخل الدرجة"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () async {
                  int score = int.tryParse(scoreController.text) ?? 0;
                  if (score <= 0) return;

                  await runSafe(() async {
                    await FirebaseService.firestore.collection("results").add({
                      "userId": userId,
                      "courseId": selectedCourseId,
                      "score": score,
                      "createdAt": FieldValue.serverTimestamp(),
                    });
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  show("تم إضافة النتيجة ✅");
                },
                child: const Text("حفظ"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _linkStudent(String userId) async {
    final studentsSnap = await FirebaseService.firestore
        .collection("students")
        .orderBy("createdAt", descending: true)
        .get();

    final students = studentsSnap.docs;

    if (!mounted) return;

    Map<String, dynamic>? selected;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title:
            const Text("🔗 ربط الطالب", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              final data = s.data();

              return ListTile(
                title: Text(data['name'] ?? "",
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['phone'] ?? "",
                    style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  selected = {
                    "id": s.id,
                    "name": data['name'],
                    "phone": data['phone'],
                  };
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );

    if (selected == null) return;

    await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .set({
      "name": selected!["name"],
      "phone": selected!["phone"],
      "studentId": selected!["id"],
    }, SetOptions(merge: true));

    if (!mounted) return;

    show("تم الربط ✅");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("🎓 إدارة الطلاب",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _header(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore
                      .collection(AppConstants.users)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LoadingWidget();
                    }

                    var users = snapshot.data!.docs;

                    var filtered = users.where((u) {
                      var data = u.data() as Map<String, dynamic>;

                      String email = (data['email'] ?? "").toLowerCase();

                      String name = (data['name'] ?? "").toLowerCase();

                      return email.contains(search.toLowerCase()) ||
                          name.contains(search.toLowerCase());
                    }).toList();

                    return ListView.builder(
                      controller: _scroll,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        var u = filtered[index];
                        var data = u.data() as Map<String, dynamic>;

                        return StudentItem(
                          userId: u.id,
                          data: data,
                          onEnroll: () => _handleEnroll(u.id, false),
                          onUnlock: () => _handleEnroll(u.id, true),
                          onVip: () => _toggleVip(u.id, data['isVIP'] ?? false),
                          onBlock: (b) => _toggleBlock(u.id, b),
                          onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditStudentPage(
                                      userId: u.id, data: data))),
                          onLink: () => _linkStudent(u.id),
                          onResult: () => _addResult(u.id),
                          onAttendance: () => _markAttendance(u.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (loading) _loading(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "بحث...",
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => search = v),
      ),
    );
  }

  Widget _loading() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }

  // 🔥🔥🔥 أهم تعديل (Multi Courses)
  void _handleEnroll(String uid, bool unlock) {
    showCoursesDialog(
      context,
      userId: uid,
      unlock: unlock,
      onSelect: (courseIds) async {
        if (courseIds.isEmpty) return;

        await runSafe(() async {
          await FirebaseService.firestore
              .collection(AppConstants.users)
              .doc(uid)
              .set({
            unlock ? "unlockedCourses" : "enrolledCourses":
                FieldValue.arrayUnion(courseIds)
          }, SetOptions(merge: true));

          show(unlock ? "تم فتح الكورسات 🔓" : "تم تسجيل الكورسات ✅");
        });
      },
    );
  }

  Future<void> _toggleVip(String id, bool current) async {
    await runSafe(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(id)
          .update({"isVIP": !current});
    });
  }

  Future<void> _toggleBlock(String id, bool current) async {
    await runSafe(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(id)
          .update({"blocked": !current});
    });
  }
}
