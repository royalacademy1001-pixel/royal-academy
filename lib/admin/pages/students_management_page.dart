import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../widgets/loading_widget.dart';
import '../widgets/courses_dialog.dart';
import 'edit_student_page.dart';

class StudentsManagementPage extends StatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  State<StudentsManagementPage> createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  final ScrollController _scroll = ScrollController();

  final Map<String, Future<bool>> _adminFutureCache = {};

  Future<List<Map<String, dynamic>>>? _usersFuture;

  bool loading = false;
  bool actionLock = false;

  String search = "";
  String filterMode = "vip";

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _text(dynamic value) {
    return value == null ? "" : value.toString().trim();
  }

  bool _bool(dynamic value) {
    return value == true;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_text(value)) ?? 0;
  }

  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  Future<bool> _checkAdmin(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(uid)
          .get();

      final data = _safeMap(doc.data());
      final role = _text(data['role']).toLowerCase();

      return _bool(data['isAdmin']) || role == 'admin';
    } catch (e) {
      debugPrint("Admin Check Error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    try {
      final snap = await FirebaseService.firestore
          .collection(AppConstants.users)
          .get();

      final users = snap.docs.map((doc) {
        final data = _safeMap(doc.data());
        data['_id'] = doc.id;
        return data;
      }).toList();

      users.sort((a, b) {
        final vipA = _bool(a['isVIP']);
        final vipB = _bool(b['isVIP']);
        if (vipA != vipB) return vipA ? -1 : 1;

        final blockedA = _bool(a['blocked']);
        final blockedB = _bool(b['blocked']);
        if (blockedA != blockedB) return blockedA ? 1 : -1;

        final nameA = _text(a['name']).toLowerCase();
        final nameB = _text(b['name']).toLowerCase();
        return nameA.compareTo(nameB);
      });

      return users.where(_isStudentUser).toList();
    } catch (e) {
      debugPrint("Load Users Error: $e");
      rethrow;
    }
  }

  bool _isStudentUser(Map<String, dynamic> data) {
    final role = _text(data['role']).toLowerCase();
    final isAdmin = _bool(data['isAdmin']);
    final instructorApproved = _bool(data['instructorApproved']);
    final instructorRequest = _bool(data['instructorRequest']);

    return !isAdmin &&
        role != "admin" &&
        role != "instructor" &&
        !instructorApproved &&
        !instructorRequest;
  }

  bool _isVip(Map<String, dynamic> data) {
    return _bool(data['isVIP']);
  }

  bool _isBlocked(Map<String, dynamic> data) {
    return _bool(data['blocked']);
  }

  bool _isLinked(Map<String, dynamic> data) {
    return _text(data['studentId']).isNotEmpty;
  }

  bool _isSubscribed(Map<String, dynamic> data) {
    return _bool(data['subscribed']);
  }

  bool _vipActionAllowed(Map<String, dynamic> data) {
    if (_isVip(data)) return true;
    show("هذه العملية متاحة لطلاب VIP فقط");
    return false;
  }

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

  Future<void> runSafe(Future<void> Function() action) async {
    if (loading || actionLock) return;

    actionLock = true;
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      await action();
    } catch (e) {
      debugPrint("Students Error: $e");
      show("حدث خطأ ❌");
    } finally {
      actionLock = false;
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _syncLinkedStudent(
    String userId,
    Map<String, dynamic> data, {
    Map<String, dynamic>? extra,
  }) async {
    final studentId = _text(data['studentId']);
    if (studentId.isEmpty) return;

    final payload = <String, dynamic>{
      "linkedUserId": userId,
      "name": _text(data['name']),
      "phone": _text(data['phone']),
      "image": _text(data['image']),
      "isVIP": _isVip(data),
      "blocked": _isBlocked(data),
      "subscribed": _isSubscribed(data),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (extra != null) {
      payload.addAll(extra);
    }

    await FirebaseService.firestore
        .collection("students")
        .doc(studentId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _markAttendance(
    String userId, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};
    if (userData.isNotEmpty && !_vipActionAllowed(userData)) return;

    await runSafe(() async {
      await FirebaseService.firestore.collection("attendance").add({
        "userId": userId,
        "studentId": _text(userData['studentId']),
        "name": _text(userData['name']),
        "phone": _text(userData['phone']),
        "isVIP": _isVip(userData),
        "status": "present",
        "date": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
        "source": "students_management",
      });

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "lastAttendanceAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        userData,
        extra: {
          "lastAttendanceAt": FieldValue.serverTimestamp(),
        },
      );

      show("تم تسجيل الحضور ✅");
    });
  }

  Future<void> _toggleVip(
    String userId,
    bool current, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};

    await runSafe(() async {
      final next = !current;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "isVIP": next,
        "vipUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        userData,
        extra: {
          "isVIP": next,
          "vipUpdatedAt": FieldValue.serverTimestamp(),
        },
      );

      show(next ? "تم تفعيل VIP ⭐" : "تم إلغاء VIP");
    });
  }

  Future<void> _toggleBlock(
    String userId,
    bool current, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};

    await runSafe(() async {
      final next = !current;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "blocked": next,
        "blockedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        userData,
        extra: {
          "blocked": next,
          "blockedAt": FieldValue.serverTimestamp(),
        },
      );

      show(next ? "تم حظر المستخدم 🚫" : "تم فك الحظر ✅");
    });
  }

  Future<void> _handleEnroll(
    String userId,
    bool unlock, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};
    if (userData.isNotEmpty && !_vipActionAllowed(userData)) return;

    showCoursesDialog(
      context,
      userId: userId,
      unlock: unlock,
      onSelect: (courseIds) async {
        if (courseIds.isEmpty) return;

        await runSafe(() async {
          final payload = <String, dynamic>{
            "updatedAt": FieldValue.serverTimestamp(),
          };

          if (unlock) {
            payload["unlockedCourses"] = FieldValue.arrayUnion(courseIds);
          } else {
            payload["enrolledCourses"] = FieldValue.arrayUnion(courseIds);
          }

          await FirebaseService.firestore
              .collection(AppConstants.users)
              .doc(userId)
              .set(payload, SetOptions(merge: true));

          await _syncLinkedStudent(userId, userData, extra: payload);

          show(unlock ? "تم فتح الكورسات 🔓" : "تم تسجيل الكورسات ✅");
        });
      },
    );
  }

  Future<void> _addResult(
    String userId, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};
    if (userData.isNotEmpty && !_vipActionAllowed(userData)) return;

    final scoreController = TextEditingController();
    String? selectedCourseId;

    try {
      showCoursesDialog(
        context,
        userId: userId,
        unlock: false,
        onSelect: (courseIds) async {
          if (courseIds.isEmpty) return;

          selectedCourseId = courseIds.first;

          if (!mounted) return;

          await showDialog(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              backgroundColor: AppColors.black,
              title: const Text(
                "📊 إضافة نتيجة",
                style: TextStyle(color: Colors.white),
              ),
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final score =
                        int.tryParse(scoreController.text.trim()) ?? 0;

                    if (score <= 0) return;

                    await runSafe(() async {
                      await FirebaseService.firestore.collection("results").add({
                        "userId": userId,
                        "studentId": _text(userData['studentId']),
                        "name": _text(userData['name']),
                        "phone": _text(userData['phone']),
                        "courseId": selectedCourseId,
                        "score": score,
                        "isVIP": _isVip(userData),
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp(),
                      });

                      await FirebaseService.firestore
                          .collection(AppConstants.users)
                          .doc(userId)
                          .set({
                        "lastResultScore": score,
                        "lastResultCourseId": selectedCourseId,
                        "lastResultAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      await _syncLinkedStudent(
                        userId,
                        userData,
                        extra: {
                          "lastResultScore": score,
                          "lastResultCourseId": selectedCourseId,
                          "lastResultAt": FieldValue.serverTimestamp(),
                        },
                      );
                    });

                    if (!mounted) return;
                    Navigator.pop(dialogCtx);
                    show("تم إضافة النتيجة ✅");
                  },
                  child: const Text("حفظ"),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      scoreController.dispose();
    }
  }

  Future<void> _linkStudent(
    String userId, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};

    if (userData.isNotEmpty && !_vipActionAllowed(userData)) return;

    final studentsSnap = await FirebaseService.firestore
        .collection("students")
        .orderBy("createdAt", descending: true)
        .get();

    final students = studentsSnap.docs.map((doc) {
      final map = _safeMap(doc.data());
      map["_id"] = doc.id;
      return map;
    }).toList();

    if (!mounted) return;

    String query = "";
    Map<String, dynamic>? selected;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = students.where((student) {
            final name = _text(student['name']).toLowerCase();
            final phone = _text(student['phone']).toLowerCase();
            return query.isEmpty ||
                name.contains(query) ||
                phone.contains(query);
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text(
              "🔗 ربط الطالب",
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setDialogState(() {
                        query = value.toLowerCase().trim();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "ابحث في الطلاب...",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              "لا يوجد طلاب",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final s = filtered[index];
                              return ListTile(
                                title: Text(
                                  _text(s['name']).isEmpty
                                      ? "Student"
                                      : _text(s['name']),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  _text(s['phone']),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                onTap: () {
                                  selected = {
                                    "id": _text(s['_id']),
                                    "name": _text(s['name']),
                                    "phone": _text(s['phone']),
                                  };
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (selected == null) return;

    await runSafe(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "name": selected!["name"],
        "phone": selected!["phone"],
        "studentId": selected!["id"],
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseService.firestore
          .collection("students")
          .doc(selected!["id"])
          .set({
        "linkedUserId": userId,
        "name": selected!["name"],
        "phone": selected!["phone"],
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      show("تم الربط ✅");
    });
  }

  Future<void> _unlinkStudent(
    String userId, [
    Map<String, dynamic>? data,
  ]) async {
    final userData = data ?? {};
    final studentId = _text(userData['studentId']);
    if (studentId.isEmpty) return;

    await runSafe(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "studentId": "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseService.firestore.collection("students").doc(studentId).set({
        "linkedUserId": "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      show("تم فصل الربط ✅");
    });
  }

  Future<void> _editStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentPage(
          userId: userId,
          data: data,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return "S";
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : "S";
    }

    final first = parts.first.isNotEmpty ? parts.first[0] : "S";
    final last = parts.last.isNotEmpty ? parts.last[0] : "S";

    return (first + last).toUpperCase();
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final selected = filterMode == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        setState(() => filterMode = value);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.black.withValues(alpha: 0.45),
      side: BorderSide(
        color: selected
            ? AppColors.gold
            : Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection(List<Map<String, dynamic>> users) {
    final total = users.length;
    final vip = users.where(_isVip).length;
    final linked = users.where(_isLinked).length;
    final blocked = users.where(_isBlocked).length;
    final subscribed = users.where(_isSubscribed).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _statCard("الطلاب", total.toString(), Icons.groups, Colors.white),
        _statCard("VIP", vip.toString(), Icons.star, AppColors.gold),
        _statCard("مربوطين", linked.toString(), Icons.link, Colors.green),
        _statCard("محظورين", blocked.toString(), Icons.block, Colors.redAccent),
        _statCard("مشتركين", subscribed.toString(), Icons.verified, Colors.blue),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث بالاسم أو الإيميل أو الهاتف...",
              prefixIcon: const Icon(Icons.search, color: AppColors.gold),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() => search = "");
                      },
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("vip", "VIP فقط", Icons.star),
                const SizedBox(width: 8),
                _filterChip("all", "الكل", Icons.people),
                const SizedBox(width: 8),
                _filterChip("linked", "مربوط", Icons.link),
                const SizedBox(width: 8),
                _filterChip("unlinked", "غير مربوط", Icons.link_off),
                const SizedBox(width: 8),
                _filterChip("blocked", "محظور", Icons.block),
                const SizedBox(width: 8),
                _filterChip("subscribed", "مشترك", Icons.verified),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, color: AppColors.gold),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "إدارة الطلاب VIP فقط",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );
  }

  Widget _emptyView(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorView(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 50,
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "اسحب لتحديث الصفحة",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _unauthorizedView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "🚫 غير مصرح بالدخول لمسؤولين فقط",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              child: const Text("رجوع"),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final vip = _isVip(data);
    final blocked = _isBlocked(data);
    final linked = _isLinked(data);
    final subscribed = _isSubscribed(data);

    switch (filterMode) {
      case "vip":
        return vip;
      case "all":
        return true;
      case "linked":
        return linked;
      case "blocked":
        return blocked;
      case "unlinked":
        return !linked;
      case "subscribed":
        return subscribed;
      default:
        return vip;
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> users) {
    final q = search.trim().toLowerCase();

    final filtered = users.where((u) {
      final name = _text(u['name']).toLowerCase();
      final email = _text(u['email']).toLowerCase();
      final phone = _text(u['phone']).toLowerCase();
      final studentId = _text(u['studentId']).toLowerCase();

      final matchesSearch = q.isEmpty ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          studentId.contains(q);

      return matchesSearch && _matchesFilter(u);
    }).toList();

    filtered.sort((a, b) {
      final vipA = _isVip(a);
      final vipB = _isVip(b);
      if (vipA != vipB) return vipA ? -1 : 1;

      final blockedA = _isBlocked(a);
      final blockedB = _isBlocked(b);
      if (blockedA != blockedB) return blockedA ? 1 : -1;

      final nameA = _text(a['name']).toLowerCase();
      final nameB = _text(b['name']).toLowerCase();
      return nameA.compareTo(nameB);
    });

    return filtered;
  }

  Widget _studentCard(Map<String, dynamic> data) {
    final userId = _text(data['_id']);
    final name = _text(data['name']).isEmpty ? "Student" : _text(data['name']);
    final email = _text(data['email']);
    final phone = _text(data['phone']);
    final vip = _isVip(data);
    final blocked = _isBlocked(data);
    final linked = _isLinked(data);
    final subscribed = _isSubscribed(data);
    final studentId = _text(data['studentId']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vip
              ? AppColors.gold.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: vip
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: vip ? AppColors.gold : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    if (studentId.isNotEmpty)
                      Text(
                        "Student ID: $studentId",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  if (vip) _badge("VIP", AppColors.gold),
                  if (blocked) _badge("محظور", Colors.red),
                  if (linked) _badge("مربوط", Colors.green),
                  if (subscribed) _badge("مشترك", Colors.blue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                label: vip ? "إلغاء VIP" : "تفعيل VIP",
                icon: Icons.star,
                color: vip ? Colors.amber : Colors.lightBlueAccent,
                onTap: () => _toggleVip(userId, vip, data),
              ),
              _actionButton(
                label: blocked ? "فك الحظر" : "حظر",
                icon: Icons.block,
                color: Colors.redAccent,
                onTap: () => _toggleBlock(userId, blocked, data),
              ),
              _actionButton(
                label: linked ? "فصل الربط" : "ربط طالب",
                icon: linked ? Icons.link_off : Icons.link,
                color: linked ? Colors.orange : Colors.green,
                onTap: () => linked
                    ? _unlinkStudent(userId, data)
                    : _linkStudent(userId, data),
              ),
              _actionButton(
                label: "تسجيل كورسات",
                icon: Icons.playlist_add,
                color: Colors.green,
                onTap: () => _handleEnroll(userId, false, data),
              ),
              _actionButton(
                label: "فتح كورسات",
                icon: Icons.lock_open,
                color: Colors.teal,
                onTap: () => _handleEnroll(userId, true, data),
              ),
              _actionButton(
                label: "إضافة نتيجة",
                icon: Icons.grade,
                color: Colors.purple,
                onTap: () => _addResult(userId, data),
              ),
              _actionButton(
                label: "حضور",
                icon: Icons.check_circle,
                color: Colors.blue,
                onTap: () => _markAttendance(userId, data),
              ),
              _actionButton(
                label: "تعديل",
                icon: Icons.edit,
                color: Colors.grey,
                onTap: () => _editStudent(userId, data),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> users) {
    final filteredUsers = _applyFilters(users);

    Widget listBody;
    if (filteredUsers.isEmpty) {
      listBody = _emptyView("لا توجد بيانات مطابقة");
    } else {
      listBody = ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final data = filteredUsers[index];
          return _studentCard(data);
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: _header(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _statsSection(users),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "عدد النتائج: ${filteredUsers.length}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.black,
                onRefresh: () async {
                  final next = _loadUsers();
                  setState(() {
                    _usersFuture = next;
                  });
                  await next;
                },
                child: listBody,
              ),
            ),
          ],
        ),
        if (loading) _loadingOverlay(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "🎓 إدارة الطلاب",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                search = "";
                filterMode = "vip";
                _usersFuture = _loadUsers();
              });
            },
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseService.auth.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final user = authSnap.data;
          if (user == null) {
            return _unauthorizedView();
          }

          final adminFuture =
              _adminFutureCache.putIfAbsent(user.uid, () => _checkAdmin(user.uid));

          return FutureBuilder<bool>(
            future: adminFuture,
            builder: (context, adminSnap) {
              if (adminSnap.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (adminSnap.data != true) {
                return _unauthorizedView();
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _usersFuture,
                builder: (context, usersSnap) {
                  if (usersSnap.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (usersSnap.hasError) {
                    return _errorView("❌ حصل خطأ في تحميل بيانات الطلاب");
                  }

                  final users = usersSnap.data ?? [];
                  return _buildContent(users);
                },
              );
            },
          );
        },
      ),
    );
  }
}