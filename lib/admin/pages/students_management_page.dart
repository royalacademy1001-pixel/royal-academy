import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

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
  String filter = "all";

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

  Future runSafe(Future Function() action) async {
    if (loading || actionLock) return;
    actionLock = true;
    setState(() => loading = true);
    try {
      await action();
    } catch (e) {
      debugPrint("Students Error: $e");
      show("حدث خطأ غير متوقع ❌");
    }
    if (mounted) setState(() => loading = false);
    actionLock = false;
  }

  Future<void> _addResult(String userId) async {

    final scoreController = TextEditingController();
    String? selectedCourseId;

    showCoursesDialog(
      context,
      userId: userId,
      unlock: false,
      onSelect: (courseId) async {

        selectedCourseId = courseId;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text("📊 إضافة نتيجة", style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "ادخل الدرجة",
              ),
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

    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    String? selectedStudentId;
    String selectedName = "";
    String selectedPhone = "";

    final studentsSnap = await FirebaseService.firestore
        .collection("students")
        .orderBy("createdAt", descending: true)
        .get();

    final students = studentsSnap.docs;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {

          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text("🔗 ربط الطالب", style: TextStyle(color: Colors.white)),

            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "الاسم (يدوي)"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "الموبايل (يدوي)"),
                  ),

                  const SizedBox(height: 20),

                  const Text("أو اختر من القائمة", style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {

                        final s = students[index];
                        final data = s.data();

                        return ListTile(
                          title: Text(data['name'] ?? "", style: const TextStyle(color: Colors.white)),
                          subtitle: Text(data['phone'] ?? "", style: const TextStyle(color: Colors.grey)),
                          onTap: () {
                            selectedStudentId = s.id;
                            selectedName = data['name'] ?? "";
                            selectedPhone = data['phone'] ?? "";

                            nameController.text = selectedName;
                            phoneController.text = selectedPhone;

                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () async {

                  String name = nameController.text.trim();
                  String phone = phoneController.text.trim();

                  if (name.isEmpty) return;

                  QuerySnapshot existing = await FirebaseService.firestore
                      .collection("students")
                      .where("phone", isEqualTo: phone)
                      .limit(1)
                      .get();

                  String finalStudentId;

                  if (existing.docs.isNotEmpty) {
                    finalStudentId = existing.docs.first.id;
                  } else {
                    final newStudent = await FirebaseService.firestore
                        .collection("students")
                        .add({
                      "name": name,
                      "phone": phone,
                      "createdAt": FieldValue.serverTimestamp(),
                      "linkedUserId": userId,
                    });
                    finalStudentId = newStudent.id;
                  }

                  await FirebaseService.firestore
                      .collection(AppConstants.users)
                      .doc(userId)
                      .set({
                    "name": name,
                    "phone": phone,
                    "linked": true,
                    "linkedByAdmin": true,
                    "studentId": finalStudentId,
                  }, SetOptions(merge: true));

                  await FirebaseService.firestore
                      .collection("students")
                      .doc(finalStudentId)
                      .set({
                    "linkedUserId": userId,
                  }, SetOptions(merge: true));

                  if (!mounted) return;
                  Navigator.pop(context);
                  show("تم الربط بنجاح ✅");
                },
                child: const Text("حفظ"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("🎓 إدارة شؤون الطلاب", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderSection(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore.collection(AppConstants.users).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("لا يوجد مستخدمين حالياً");

                    var filteredUsers = snapshot.data!.docs.where((u) {
                      var data = u.data() as Map<String, dynamic>;
                      String email = (data['email'] ?? "").toLowerCase();
                      String name = (data['name'] ?? "").toLowerCase();
                      bool vip = data['isVIP'] ?? false;
                      bool blocked = data['blocked'] ?? false;

                      bool matchSearch = email.contains(search.toLowerCase()) || name.contains(search.toLowerCase());
                      bool matchFilter = (filter == "all") || (filter == "vip" && vip) || (filter == "blocked" && blocked);

                      return matchSearch && matchFilter;
                    }).toList();

                    if (filteredUsers.isEmpty) return _buildEmptyState("لم نجد نتائج لهذا البحث");

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: filteredUsers.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        var u = filteredUsers[index];
                        var data = u.data() as Map<String, dynamic>;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StudentItem(
                            userId: u.id,
                            data: data,
                            extraInfo: "📚 ${data['enrolledCourses']?.length ?? 0} | 🔓 ${data['unlockedCourses']?.length ?? 0}",
                            onEnroll: () => _handleEnroll(u.id, false),
                            onUnlock: () => _handleEnroll(u.id, true),
                            onVip: () => _toggleVip(u.id, data['isVIP'] ?? false),
                            onBlock: (isBlocked) => _toggleBlock(u.id, isBlocked),
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditStudentPage(userId: u.id, data: data))),
                            onLink: () => _linkStudent(u.id),
                            onResult: () => _addResult(u.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          if (loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث بالاسم أو البريد الإلكتروني...",
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.gold, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => search = val),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("الكل", "all", Icons.group),
                const SizedBox(width: 10),
                _filterChip("VIP ⭐", "vip", Icons.star),
                const SizedBox(width: 10),
                _filterChip("المحظورين", "blocked", Icons.block),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text, String value, IconData icon) {
    bool isSelected = filter == value;
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (val) => setState(() => filter = value),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : AppColors.gold),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.black,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.gold : Colors.white10)),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 15),
              Text("جاري معالجة الطلب...", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEnroll(String uid, bool unlock) {
    showCoursesDialog(context, userId: uid, unlock: unlock, onSelect: (courseId) async {
      await runSafe(() async {
        await FirebaseService.firestore.collection(AppConstants.users).doc(uid).set({
          unlock ? "unlockedCourses" : "enrolledCourses": FieldValue.arrayUnion([courseId])
        }, SetOptions(merge: true));
        show(unlock ? "تم فتح الكورس 🔓" : "تم تسجيل الطالب ✅");
      });
    });
  }

  Future<void> _toggleVip(String id, bool current) async {
    await runSafe(() async {
      await FirebaseService.firestore.collection(AppConstants.users).doc(id).update({"isVIP": !current});
      show(!current ? "تم تفعيل VIP ⭐" : "تم إلغاء VIP ❌");
    });
  }

  Future<void> _toggleBlock(String id, bool current) async {
    await runSafe(() async {
      await FirebaseService.firestore.collection(AppConstants.users).doc(id).update({"blocked": !current});
      show(!current ? "تم الحظر 🚫" : "تم فك الحظر ✅");
    });
  }
}