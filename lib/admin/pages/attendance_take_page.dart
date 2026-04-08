import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class AttendanceTakePage extends StatefulWidget {
  final String? userId;
  final String? sessionId;
  final String? sessionName;
  final String? subjectId;
  final String? subjectName;

  const AttendanceTakePage({
    super.key,
    this.userId,
    this.sessionId,
    this.sessionName,
    this.subjectId,
    this.subjectName,
  });

  @override
  State<AttendanceTakePage> createState() => _AttendanceTakePageState();
}

class _AttendanceTakePageState extends State<AttendanceTakePage> {
  String search = "";
  bool loading = false;

  Set<String> markedStudents = {};

  String todayId() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  String selectedSessionId = "";
  String selectedSessionName = "";
  String selectedSubjectId = "";
  String selectedSubjectName = "";

  bool lateMode = false;

  @override
  void initState() {
    super.initState();

    selectedSessionId = widget.sessionId ?? "";
    selectedSessionName = widget.sessionName ?? "";
    selectedSubjectId = widget.subjectId ?? "";
    selectedSubjectName = widget.subjectName ?? "";

    Future.microtask(() async {
      if (selectedSessionId.isNotEmpty) {
        await _createSessionIfNotExists();
      } else {
        await _loadFirstSession();
      }
      await _loadTodayAttendance();
    });
  }

  Future<void> _createSessionIfNotExists() async {
    if (selectedSessionId.isEmpty) return;

    try {
      final existing = await FirebaseService.firestore
          .collection("attendance_sessions")
          .where("sessionId", isEqualTo: selectedSessionId)
          .where("date", isEqualTo: todayId())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        selectedSessionId = existing.docs.first.id;
        return;
      }

      final doc = await FirebaseService.firestore
          .collection("attendance_sessions")
          .add({
        "sessionId": selectedSessionId,
        "sessionName": selectedSessionName,
        "subjectId": selectedSubjectId,
        "subjectName": selectedSubjectName,
        "date": todayId(),
        "createdAt": FieldValue.serverTimestamp(),
        "totalStudents": 0,
        "presentCount": 0,
        "absentCount": 0,
      });

      selectedSessionId = doc.id;
    } catch (_) {}
  }

  Future<void> _loadFirstSession() async {
    try {
      final snap = await FirebaseService.firestore
          .collection("attendance_sessions")
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        selectedSessionId = snap.docs.first.id;
        final data = snap.docs.first.data() as Map<String, dynamic>? ?? {};
        selectedSessionName =
            (data['sessionName'] ?? "").toString();
        selectedSubjectName =
            (data['subjectName'] ?? "").toString();
        selectedSubjectId =
            (data['subjectId'] ?? "").toString();
      } else {
        selectedSessionId = "";
        selectedSessionName = "";
        markedStudents = {};
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadTodayAttendance() async {
    if (selectedSessionId.isEmpty) {
      markedStudents = {};
      if (mounted) setState(() {});
      return;
    }

    try {
      final snap = await FirebaseService.firestore
          .collection("attendance_sessions")
          .doc(selectedSessionId)
          .collection("records")
          .get();

      markedStudents = snap.docs.map((e) => e.id).toSet();

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> markAttendance(String studentId, String name) async {
    if (selectedSessionId.isEmpty) {
      _show("اختار حصة الأول");
      return;
    }

    if (markedStudents.contains(studentId)) {
      _show("مسجل بالفعل");
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);

    try {
      final userDoc = await FirebaseService.firestore
          .collection("users")
          .doc(studentId)
          .get();

      final userData = userDoc.data() ?? {};

      await FirebaseService.firestore
          .collection("attendance_sessions")
          .doc(selectedSessionId)
          .collection("records")
          .doc(studentId)
          .set({
        "userId": studentId,
        "name": name,
        "phone": (userData['phone'] ?? "").toString(),
        "email": (userData['email'] ?? "").toString(),
        "year": (userData['year'] ?? "").toString(),
        "term": (userData['term'] ?? "").toString(),
        "isVIP": userData['isVIP'] == true,
        "blocked": userData['blocked'] == true,
        "present": true,
        "late": lateMode,
        "sessionId": selectedSessionId,
        "sessionName": selectedSessionName,
        "subjectName": selectedSubjectName,
        "sessionDate": todayId(),
        "sessionTime": "",
        "sessionDateTime": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      markedStudents.add(studentId);

      await _updateSessionStats();

      _show("تم تسجيل حضور $name ✅");
    } catch (_) {
      _show("خطأ ❌");
    }

    if (mounted) setState(() => loading = false);
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> markAll(List<QueryDocumentSnapshot> students) async {
    if (selectedSessionId.isEmpty) {
      _show("اختار حصة الأول");
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);

    try {
      WriteBatch batch = FirebaseService.firestore.batch();

      for (var s in students) {
        if (markedStudents.contains(s.id)) continue;

        final data = s.data() as Map<String, dynamic>? ?? {};

        batch.set(
          FirebaseService.firestore
              .collection("attendance_sessions")
              .doc(selectedSessionId)
              .collection("records")
              .doc(s.id),
          {
            "userId": s.id,
            "name": (data['name'] ?? "").toString(),
            "phone": (data['phone'] ?? "").toString(),
            "email": (data['email'] ?? "").toString(),
            "year": (data['year'] ?? "").toString(),
            "term": (data['term'] ?? "").toString(),
            "isVIP": data['isVIP'] == true,
            "blocked": data['blocked'] == true,
            "present": true,
            "late": lateMode,
            "sessionId": selectedSessionId,
            "sessionName": selectedSessionName,
            "subjectName": selectedSubjectName,
            "sessionDate": todayId(),
            "sessionTime": "",
            "sessionDateTime": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _loadTodayAttendance();
      await _updateSessionStats();

      _show("تم تسجيل حضور الجميع 🔥");
    } catch (_) {
      _show("خطأ ❌");
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _updateSessionStats() async {
    try {
      if (selectedSessionId.isEmpty) return;

      final snap = await FirebaseService.firestore
          .collection("attendance_sessions")
          .doc(selectedSessionId)
          .collection("records")
          .get();

      final total = snap.docs.length;
      final present = snap.docs
          .where((e) =>
              ((e.data() as Map<String, dynamic>? ?? {})['present'] ?? false) ==
              true)
          .length;

      await FirebaseService.firestore
          .collection("attendance_sessions")
          .doc(selectedSessionId)
          .update({
        "totalStudents": total,
        "presentCount": present,
        "absentCount": total - present,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selectedSessionName.isEmpty ? "📋 تسجيل الحضور" : selectedSessionName),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: Icon(
              lateMode ? Icons.access_time : Icons.access_time_outlined,
              color: lateMode ? Colors.orange : Colors.white,
            ),
            onPressed: () {
              if (!mounted) return;
              setState(() => lateMode = !lateMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.green),
            onPressed: () async {
              final snap = await FirebaseService.firestore
                  .collection("users")
                  .get();

              markAll(snap.docs);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) {
                    setState(() => search = v.toLowerCase());
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "بحث عن طالب...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseService.firestore.collection("users").snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final students = snapshot.data!.docs.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final name =
                          (data['name'] ?? "").toString().toLowerCase();
                      final year =
                          (data['year'] ?? "").toString();
                      final term =
                          (data['term'] ?? "").toString();
                      return name.contains(search) &&
                          (selectedSubjectId.isEmpty ||
                              (year.isNotEmpty && term.isNotEmpty));
                    }).toList();

                    if (students.isEmpty) {
                      return const Center(
                        child: Text("لا يوجد طلاب"),
                      );
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final data =
                            students[index].data() as Map<String, dynamic>? ??
                                {};
                        final name = (data['name'] ?? "بدون اسم").toString();
                        final id = students[index].id;

                        final marked = markedStudents.contains(id);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              name,
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              marked
                                  ? (lateMode ? "⏰ متأخر" : "✅ تم الحضور")
                                  : "⏳ لم يسجل",
                              style: TextStyle(
                                color: marked
                                    ? (lateMode ? Colors.orange : Colors.green)
                                    : Colors.grey,
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: marked
                                    ? Colors.grey
                                    : (lateMode ? Colors.orange : Colors.green),
                              ),
                              onPressed: marked
                                  ? null
                                  : () => markAttendance(id, name),
                              child: Text(marked ? "تم" : (lateMode ? "متأخر" : "حضور")),
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
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}