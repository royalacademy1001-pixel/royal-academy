import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '/shared/widgets/loading_widget.dart';
import 'edit_student_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<List<Map<String, dynamic>>>? _usersFuture;
  Future<List<Map<String, dynamic>>>? _coursesFuture;

  final Map<String, Future<bool>> _adminCache = {};

  String search = "";
  String filterMode = "all";
  String? selectedCourseId;
  String selectedCourseTitle = "";

  bool loadingAction = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
    _coursesFuture = _loadCourses();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
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
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
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

      return _bool(data['isAdmin']) || role == "admin";
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

      return users;
    } catch (e) {
      debugPrint("Load Users Error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadCourses() async {
    try {
      final snap = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .get();

      final courses = snap.docs.map((doc) {
        final data = _safeMap(doc.data());
        data['_id'] = doc.id;
        return data;
      }).toList();

      courses.sort((a, b) {
        final titleA = _text(a['title']).toLowerCase();
        final titleB = _text(b['title']).toLowerCase();
        return titleA.compareTo(titleB);
      });

      return courses;
    } catch (e) {
      debugPrint("Load Courses Error: $e");
      return [];
    }
  }

  Future<void> _refreshAll() async {
    final nextUsers = _loadUsers();
    final nextCourses = _loadCourses();

    if (mounted) {
      setState(() {
        _usersFuture = nextUsers;
        _coursesFuture = nextCourses;
        _adminCache.clear();
      });
    }

    await Future.wait([nextUsers, nextCourses]);
  }

  Future<void> _refreshUsers() async {
    final nextUsers = _loadUsers();

    if (mounted) {
      setState(() {
        _usersFuture = nextUsers;
      });
    }

    await nextUsers;
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

  bool _isAdminUser(Map<String, dynamic> data) {
    final role = _text(data['role']).toLowerCase();
    return _bool(data['isAdmin']) || role == "admin";
  }

  bool _isInstructor(Map<String, dynamic> data) {
    return _bool(data['instructorApproved']) || _text(data['role']).toLowerCase() == "instructor";
  }

  bool _hasPendingInstructorRequest(Map<String, dynamic> data) {
    return _bool(data['instructorRequest']) && !_bool(data['instructorApproved']);
  }

  String _courseTitleById(List<Map<String, dynamic>> courses, String? id) {
    if (id == null || id.isEmpty) return "";
    for (final course in courses) {
      if (_text(course['_id']) == id) {
        final title = _text(course['title']);
        return title.isEmpty ? id : title;
      }
    }
    return "";
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

  Future<bool> confirm(String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          TextButton(
            child: const Text("تأكيد"),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> runAction(Future<void> Function() action, String msg) async {
    if (loadingAction) return;

    setState(() => loadingAction = true);

    try {
      await action();
      if (mounted) show(msg);
    } catch (e) {
      debugPrint("Users Action Error: $e");
      if (mounted) show("حصل خطأ ❌");
    }

    if (mounted) {
      setState(() => loadingAction = false);
    } else {
      loadingAction = false;
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

  Future<void> _toggleSubscription(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "subscribed": next,
        "subscriptionUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "subscribed": next,
          "subscriptionUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تفعيل الاشتراك ✅" : "تم إلغاء الاشتراك ❌");

    await _refreshUsers();
  }

  Future<void> _toggleVip(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
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
        data,
        extra: {
          "isVIP": next,
          "vipUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تفعيل VIP ⭐" : "تم إلغاء VIP");

    await _refreshUsers();
  }

  Future<void> _toggleBlock(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
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
        data,
        extra: {
          "blocked": next,
          "blockedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم حظر المستخدم 🚫" : "تم فك الحظر ✅");

    await _refreshUsers();
  }

  Future<void> _makeAdmin(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "isAdmin": next,
        "adminUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "isAdmin": next,
          "adminUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تحويله Admin 👑" : "تم إزالة Admin ❌");

    await _refreshUsers();
  }

  Future<void> _approveInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": true,
        "instructorRequest": false,
        "isInstructor": true,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": true,
          "instructorRequest": false,
          "isInstructor": true,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم قبول المدرس 🎓");

    await _refreshUsers();
  }

  Future<void> _rejectInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": false,
        "instructorRequest": false,
        "isInstructor": false,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": false,
          "instructorRequest": false,
          "isInstructor": false,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم رفض طلب المدرس ❌");

    await _refreshUsers();
  }

  Future<void> _removeInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": false,
        "instructorRequest": false,
        "isInstructor": false,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": false,
          "instructorRequest": false,
          "isInstructor": false,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم إلغاء صفة المدرس 🚫");

    await _refreshUsers();
  }

  Future<void> _unlockCourse(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    final courseId = selectedCourseId!;
    final title = selectedCourseTitle.isEmpty ? "الكورس" : selectedCourseTitle;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "unlockedCourses": FieldValue.arrayUnion([courseId]),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "lastUnlockedCourseId": courseId,
          "lastUnlockedCourseTitle": title,
        },
      );
    }, "تم فتح $title 🔓");

    await _refreshUsers();
  }

  Future<void> _lockCourse(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    final courseId = selectedCourseId!;
    final title = selectedCourseTitle.isEmpty ? "الكورس" : selectedCourseTitle;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "unlockedCourses": FieldValue.arrayRemove([courseId]),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "lastLockedCourseId": courseId,
          "lastLockedCourseTitle": title,
        },
      );
    }, "تم قفل $title 🔒");

    await _refreshUsers();
  }

  Future<void> _markAttendance(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!_isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

    await runAction(() async {
      await FirebaseService.firestore.collection("attendance").add({
        "userId": userId,
        "studentId": _text(data['studentId']),
        "name": _text(data['name']),
        "phone": _text(data['phone']),
        "isVIP": true,
        "status": "present",
        "date": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
        "source": "users_page",
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
        data,
        extra: {
          "lastAttendanceAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم تسجيل الحضور ✅");

    await _refreshUsers();
  }

  Future<void> _addResult(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!_isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    final scoreController = TextEditingController();

    try {
      final ok = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
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
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("حفظ"),
                ),
              ],
            ),
          ) ??
          false;

      if (!ok) return;

      final score = int.tryParse(scoreController.text.trim()) ?? 0;
      if (score <= 0) {
        show("الدرجة غير صحيحة");
        return;
      }

      final courseId = selectedCourseId!;
      final courseTitle = selectedCourseTitle.isEmpty ? "" : selectedCourseTitle;

      await runAction(() async {
        await FirebaseService.firestore.collection("results").add({
          "userId": userId,
          "studentId": _text(data['studentId']),
          "name": _text(data['name']),
          "phone": _text(data['phone']),
          "courseId": courseId,
          "courseTitle": courseTitle,
          "score": score,
          "isVIP": true,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          "source": "users_page",
        });

        await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(userId)
            .set({
          "lastResultScore": score,
          "lastResultCourseId": courseId,
          "lastResultCourseTitle": courseTitle,
          "lastResultAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _syncLinkedStudent(
          userId,
          data,
          extra: {
            "lastResultScore": score,
            "lastResultCourseId": courseId,
            "lastResultCourseTitle": courseTitle,
            "lastResultAt": FieldValue.serverTimestamp(),
          },
        );
      }, "تم إضافة النتيجة ✅");

      await _refreshUsers();
    } finally {
      scoreController.dispose();
    }
  }

  Future<void> _linkStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!_isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = students.where((student) {
            final name = _text(student['name']).toLowerCase();
            final phone = _text(student['phone']).toLowerCase();
            final id = _text(student['_id']).toLowerCase();

            return query.isEmpty ||
                name.contains(query) ||
                phone.contains(query) ||
                id.contains(query);
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

    await runAction(() async {
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
    }, "تم الربط ✅");

    await _refreshUsers();
  }

  Future<void> _unlinkStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final studentId = _text(data['studentId']);
    if (studentId.isEmpty) return;

    await runAction(() async {
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
    }, "تم فصل الربط ✅");

    await _refreshUsers();
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
          data: Map<String, dynamic>.from(data),
        ),
      ),
    );

    await _refreshUsers();
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
    final blocked = users.where(_isBlocked).length;
    final linked = users.where(_isLinked).length;
    final subscribed = users.where(_isSubscribed).length;
    final admins = users.where(_isAdminUser).length;
    final instructors = users.where(_isInstructor).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _statCard("الإجمالي", total.toString(), Icons.groups, Colors.white),
        _statCard("VIP", vip.toString(), Icons.star, AppColors.gold),
        _statCard("محظورين", blocked.toString(), Icons.block, Colors.redAccent),
        _statCard("مربوطين", linked.toString(), Icons.link, Colors.green),
        _statCard("مشتركين", subscribed.toString(), Icons.verified, Colors.blue),
        _statCard("Admin", admins.toString(), Icons.admin_panel_settings, Colors.orange),
        _statCard("مدرسين", instructors.toString(), Icons.school, Colors.purple),
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
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث بالاسم أو الإيميل أو الهاتف أو Student ID...",
              prefixIcon: const Icon(Icons.search, color: AppColors.gold),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
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
                _filterChip("all", "الكل", Icons.people),
                const SizedBox(width: 8),
                _filterChip("vip", "VIP فقط", Icons.star),
                const SizedBox(width: 8),
                _filterChip("subscribed", "مشترك", Icons.verified),
                const SizedBox(width: 8),
                _filterChip("linked", "مربوط", Icons.link),
                const SizedBox(width: 8),
                _filterChip("unlinked", "غير مربوط", Icons.link_off),
                const SizedBox(width: 8),
                _filterChip("blocked", "محظور", Icons.block),
                const SizedBox(width: 8),
                _filterChip("admins", "Admins", Icons.admin_panel_settings),
                const SizedBox(width: 8),
                _filterChip("instructors", "مدرسين", Icons.school),
                const SizedBox(width: 8),
                _filterChip("requests", "طلبات المدرسين", Icons.pending_actions),
                const SizedBox(width: 8),
                _filterChip("students", "طلاب فقط", Icons.person),
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
                    "لوحة تحكم المستخدمين كاملة: VIP / Admin / Instructor / Courses / Results / Attendance / Link / Block",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
              "🚫 غير مصرح بالدخول",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "هذه الصفحة مخصصة للمسؤولين فقط",
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
    final isAdmin = _isAdminUser(data);
    final instructor = _isInstructor(data);
    final request = _hasPendingInstructorRequest(data);

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
      case "admins":
        return isAdmin;
      case "instructors":
        return instructor;
      case "requests":
        return request;
      case "students":
        return _isStudentUser(data);
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
      final role = _text(u['role']).toLowerCase();

      final matchesSearch = q.isEmpty ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          studentId.contains(q) ||
          role.contains(q);

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

  Widget _buildCourseSelector() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "جاري تحميل الكورسات...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              "❌ حدث خطأ في تحميل الكورسات",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              "لا توجد كورسات متاحة",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final ids = courses.map((e) => _text(e['_id'])).toSet();
        if (selectedCourseId != null && !ids.contains(selectedCourseId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                selectedCourseId = null;
                selectedCourseTitle = "";
              });
            }
          });
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "اختيار كورس للتحكم في الصلاحيات",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCourseId,
                dropdownColor: AppColors.black,
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "اختر كورس",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: courses.map((course) {
                  final id = _text(course['_id']);
                  final title = _text(course['title']).isEmpty ? id : _text(course['title']);
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(title, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  final title = _courseTitleById(courses, value);
                  setState(() {
                    selectedCourseId = value;
                    selectedCourseTitle = title;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _studentCard(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final userId = _text(data['_id']);
    final name = _text(data['name']).isEmpty ? "Student" : _text(data['name']);
    final email = _text(data['email']);
    final phone = _text(data['phone']);
    final vip = _isVip(data);
    final blocked = _isBlocked(data);
    final linked = _isLinked(data);
    final subscribed = _isSubscribed(data);
    final isAdmin = _isAdminUser(data);
    final isInstructor = _isInstructor(data);
    final pendingInstructor = _hasPendingInstructorRequest(data);
    final isMe = userId == currentUserId;

    final studentId = _text(data['studentId']);
    final lastResultScore = _int(data['lastResultScore']);
    final lastAttendanceAt = _text(data['lastAttendanceAt']);
    final subscriptionEnd = _text(data['subscriptionEnd']);
    final role = _text(data['role']);

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
                  name.trim().isEmpty ? "U" : name.trim().substring(0, 1).toUpperCase(),
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
              PopupMenuButton<String>(
                color: AppColors.black,
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) async {
                  switch (value) {
                    case "edit":
                      await _editStudent(userId, data);
                      break;
                    case "subscription":
                      await _toggleSubscription(userId, subscribed, data);
                      break;
                    case "vip":
                      await _toggleVip(userId, vip, data);
                      break;
                    case "block":
                      if (await confirm(blocked ? "فك الحظر؟" : "حظر المستخدم؟")) {
                        await _toggleBlock(userId, blocked, data);
                      }
                      break;
                    case "admin":
                      if (!isMe && await confirm(isAdmin ? "إزالة صفة Admin؟" : "جعل المستخدم Admin؟")) {
                        await _makeAdmin(userId, isAdmin, data);
                      }
                      break;
                    case "unlockCourse":
                      if (selectedCourseId != null &&
                          await confirm("فتح الكورس المحدد لهذا المستخدم؟")) {
                        await _unlockCourse(userId, data);
                      }
                      break;
                    case "lockCourse":
                      if (selectedCourseId != null &&
                          await confirm("قفل الكورس المحدد لهذا المستخدم؟")) {
                        await _lockCourse(userId, data);
                      }
                      break;
                    case "link":
                      await _linkStudent(userId, data);
                      break;
                    case "unlink":
                      if (await confirm("فصل الربط الحالي؟")) {
                        await _unlinkStudent(userId, data);
                      }
                      break;
                    case "attendance":
                      await _markAttendance(userId, data);
                      break;
                    case "result":
                      await _addResult(userId, data);
                      break;
                    case "approveInstructor":
                      await _approveInstructor(userId, data);
                      break;
                    case "rejectInstructor":
                      await _rejectInstructor(userId, data);
                      break;
                    case "removeInstructor":
                      await _removeInstructor(userId, data);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: Text("✏️ تعديل", style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "subscription",
                    child: Text(
                      subscribed ? "💳 إلغاء الاشتراك" : "💳 تفعيل الاشتراك",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: "vip",
                    child: Text(
                      vip ? "⭐ إلغاء VIP" : "⭐ تفعيل VIP",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (!isMe)
                    PopupMenuItem(
                      value: "block",
                      child: Text(
                        blocked ? "✅ فك الحظر" : "🚫 حظر المستخدم",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (!isMe)
                    PopupMenuItem(
                      value: "admin",
                      child: Text(
                        isAdmin ? "❌ إزالة Admin" : "👑 جعل Admin",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (selectedCourseId != null) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: "unlockCourse",
                      child: Text(
                        "🔓 فتح الكورس المحدد",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    PopupMenuItem(
                      value: "lockCourse",
                      child: Text(
                        "🔒 قفل الكورس المحدد",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "link",
                    child: Text(
                      linked ? "🔗 إعادة ربط طالب" : "🔗 ربط بطالب",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (linked)
                    PopupMenuItem(
                      value: "unlink",
                      child: Text(
                        "🔗 فصل الربط",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "attendance",
                    child: Text(
                      "✅ تسجيل حضور",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: "result",
                    child: Text(
                      "📊 إضافة نتيجة",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (pendingInstructor)
                    const PopupMenuDivider(),
                  if (pendingInstructor)
                    const PopupMenuItem(
                      value: "approveInstructor",
                      child: Text(
                        "🎓 قبول كمدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (pendingInstructor)
                    const PopupMenuItem(
                      value: "rejectInstructor",
                      child: Text(
                        "❌ رفض طلب المدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (isInstructor)
                    const PopupMenuItem(
                      value: "removeInstructor",
                      child: Text(
                        "🚫 إلغاء صفة المدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (vip) _badge("VIP", AppColors.gold),
              if (blocked) _badge("محظور", Colors.red),
              if (linked) _badge("مربوط", Colors.green),
              if (subscribed) _badge("مشترك", Colors.blue),
              if (isAdmin) _badge("Admin", Colors.orange),
              if (isInstructor) _badge("مدرس", Colors.purple),
              if (pendingInstructor) _badge("طلب مدرس", Colors.deepOrange),
              if (studentId.isNotEmpty) _badge("Student Linked", Colors.teal),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "آخر نتيجة: ${lastResultScore > 0 ? lastResultScore.toString() : "لا يوجد"}   |   آخر حضور: ${lastAttendanceAt.isNotEmpty ? lastAttendanceAt : "لا يوجد"}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (subscriptionEnd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "انتهاء الاشتراك: $subscriptionEnd",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Role: $role",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
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
                onTap: () => _unlockCourse(userId, data),
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

  Widget _buildContent(List<Map<String, dynamic>> users, String currentUserId) {
    final filteredUsers = _applyFilters(users);

    Widget listBody;
    if (filteredUsers.isEmpty) {
      listBody = _emptyView("لا توجد بيانات مطابقة");
    } else {
      listBody = ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final data = filteredUsers[index];
          return _studentCard(data, currentUserId);
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
              child: _buildCourseSelector(),
            ),
            const SizedBox(height: 12),
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
                onRefresh: _refreshAll,
                child: listBody,
              ),
            ),
          ],
        ),
        if (loadingAction) _loadingOverlay(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "👥 Users Dashboard",
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              searchController.clear();
              setState(() {
                search = "";
                filterMode = "all";
                selectedCourseId = null;
                selectedCourseTitle = "";
              });
              await _refreshAll();
            },
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox(),
              ),
            ),
          ),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnap) {
              if (authSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingWidget());
              }

              final user = authSnap.data;
              if (user == null) {
                return _unauthorizedView();
              }

              final adminFuture = _adminCache.putIfAbsent(
                user.uid,
                () => _checkAdmin(user.uid),
              );

              return FutureBuilder<bool>(
                future: adminFuture,
                builder: (context, adminSnap) {
                  if (adminSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingWidget());
                  }

                  if (adminSnap.hasError) {
                    return _errorView("❌ حدث خطأ أثناء التحقق من الصلاحيات");
                  }

                  if (adminSnap.data != true) {
                    return _unauthorizedView();
                  }

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _usersFuture,
                    builder: (context, usersSnap) {
                      if (usersSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: LoadingWidget());
                      }

                      if (usersSnap.hasError) {
                        return _errorView("❌ حدث خطأ في تحميل بيانات المستخدمين");
                      }

                      final users = usersSnap.data ?? [];
                      return _buildContent(users, user.uid);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}