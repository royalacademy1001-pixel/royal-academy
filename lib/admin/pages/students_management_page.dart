import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '/shared/widgets/loading_widget.dart';
import '../widgets/courses_dialog.dart';
import 'edit_student_page.dart';

class StudentsManagementPage extends StatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  State<StudentsManagementPage> createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  final ScrollController _scroll = ScrollController();

  Future<List<Map<String, dynamic>>>? _usersFuture;

  bool loading = false;
  bool actionLock = false;

  String search = "";
  String filterMode = "all";

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

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    try {
      final snap =
          await FirebaseService.firestore.collection(AppConstants.users).get();

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

      return users;
    } catch (e) {
      debugPrint("Load Users Error: $e");
      rethrow;
    }
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
    return true;
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
                    final score = int.tryParse(scoreController.text.trim()) ?? 0;

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
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : "S";
    }

    final first = parts.first.isNotEmpty ? parts.first[0] : "S";
    final last = parts.last.isNotEmpty ? parts.last[0] : "S";

    return (first + last).toUpperCase();
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
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
            size: 14,
            color: selected ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.black.withValues(alpha: 0.45),
      side: BorderSide(
        color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.08),
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
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
      spacing: 8,
      runSpacing: 8,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث...",
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("vip", "VIP", Icons.star),
                const SizedBox(width: 6),
                _filterChip("all", "الكل", Icons.people),
                const SizedBox(width: 6),
                _filterChip("linked", "مربوط", Icons.link),
                const SizedBox(width: 6),
                _filterChip("unlinked", "غير مربوط", Icons.link_off),
                const SizedBox(width: 6),
                _filterChip("blocked", "محظور", Icons.block),
                const SizedBox(width: 6),
                _filterChip("subscribed", "مشترك", Icons.verified),
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
          height: 200,
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
          height: 200,
          child: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _studentCard(Map<String, dynamic> data) {
    final userId = _text(data['_id']);
    final name = _text(data['name']).isEmpty ? "Student" : _text(data['name']);
    final vip = _isVip(data);
    final blocked = _isBlocked(data);
    final linked = _isLinked(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Text(_initials(name)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (vip) _badge("VIP", AppColors.gold),
              if (blocked) _badge("X", Colors.red),
              if (linked) _badge("L", Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _actionButton(
                label: "VIP",
                icon: Icons.star,
                color: Colors.amber,
                onTap: () => _toggleVip(userId, vip, data),
              ),
              _actionButton(
                label: "Block",
                icon: Icons.block,
                color: Colors.red,
                onTap: () => _toggleBlock(userId, blocked, data),
              ),
              _actionButton(
                label: "Edit",
                icon: Icons.edit,
                color: Colors.grey,
                onTap: () => _editStudent(userId, data),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> users) {
    final filteredUsers = _applyFilters(users);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: _header(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _statsSection(users),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final next = _loadUsers();
                  setState(() {
                    _usersFuture = next;
                  });
                  await next;
                },
                child: filteredUsers.isEmpty
                    ? _emptyView("لا يوجد بيانات")
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, i) =>
                            _studentCard(filteredUsers[i]),
                      ),
              ),
            ),
          ],
        ),
        if (loading) _loadingOverlay(),
      ],
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> users) {
    final q = search.toLowerCase();
    return users.where((u) {
      final name = _text(u['name']).toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إدارة الطلاب"),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (_, snap) {
          if (!snap.hasData) return const LoadingWidget();
          return _buildContent(snap.data!);
        },
      ),
    );
  }
}