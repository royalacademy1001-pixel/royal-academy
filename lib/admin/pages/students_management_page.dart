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
  String filter = "all"; // all | vip | blocked

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

  // الدوال (toggleVip, toggleBlock) ستبقى كما هي في منطقها البرمجي لضمان الربط السليم مع Firebase

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
              // 🔍 قسم البحث والفلترة المطور
              _buildHeaderSection(),

              // 🔥 القائمة الذكية
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
                      bool vip = data['subscribed'] ?? false;
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
                        
                        // تمرير البيانات لـ StudentItem المطور عندك
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StudentItem(
                            userId: u.id,
                            data: data,
                            extraInfo: "📚 ${data['enrolledCourses']?.length ?? 0} | 🔓 ${data['unlockedCourses']?.length ?? 0}",
                            onEnroll: () => _handleEnroll(u.id, false),
                            onUnlock: () => _handleEnroll(u.id, true),
                            onVip: () => _toggleVip(u.id, data['subscribed'] ?? false),
                            onBlock: (isBlocked) => _toggleBlock(u.id, isBlocked),
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditStudentPage(userId: u.id, data: data))),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // 🔥 Loading Overlay الاحترافي
          if (loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
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
              fillColor: Colors.white.withOpacity(0.05),
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
          Icon(Icons.person_search_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
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

  // منطق الدوال المختصر (تم استدعاؤه في الـ Builder)
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
      await FirebaseService.firestore.collection(AppConstants.users).doc(id).update({"subscribed": !current});
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