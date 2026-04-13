import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../core/firebase_service.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../../shared/widgets/loading_widget.dart';
import 'subject_sessions_page.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String studentSearch = "";
  String reportSearch = "";

  String selectedYear = "سنة أولى";
  String selectedTerm = "ترم أول";
  String? selectedSubjectId;
  String selectedSubjectName = "";

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool saving = false;

  bool lateMode = false;

  String selectedSessionId = "";
  String selectedSessionName = "";

  final Map<String, bool> attendanceMap = {};
  final Map<String, double> attendancePercentageCache = {};
  List<QueryDocumentSnapshot> _lastVisibleStudents = [];

  final List<String> years = const ["سنة أولى", "سنة تانية"];
  final List<String> terms = const ["ترم أول", "ترم تاني"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendancePercentages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  String _formatTime(TimeOfDay time) {
    return "${_two(time.hour)}:${_two(time.minute)}";
  }

  bool _isStudent(Map<String, dynamic> data) {
    return data['isAdmin'] != true && data['instructorApproved'] != true;
  }

  bool _matchesStudent(Map<String, dynamic> data) {
    final name = (data['name'] ?? "").toString().toLowerCase();
    final phone = (data['phone'] ?? "").toString().toLowerCase();
    final email = (data['email'] ?? "").toString().toLowerCase();
    final year = (data['year'] ?? "").toString().trim();
    final term = (data['term'] ?? "").toString().trim();

    final search = studentSearch.toLowerCase().trim();

    final searchMatch = search.isEmpty ||
        name.contains(search) ||
        phone.contains(search) ||
        email.contains(search);
    final yearMatch = year.isEmpty || year == selectedYear;
    final termMatch = term.isEmpty || term == selectedTerm;

    return searchMatch && yearMatch && termMatch && _isStudent(data);
  }

  List<QueryDocumentSnapshot> _filterStudents(
      List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return _matchesStudent(data);
    }).toList();
  }

  List<QueryDocumentSnapshot> _filterSessions(
      List<QueryDocumentSnapshot> docs) {
    final search = reportSearch.toLowerCase().trim();

    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final year = (data['year'] ?? "").toString().trim();
      final term = (data['term'] ?? "").toString().trim();
      final subjectName = (data['subjectName'] ?? "").toString().toLowerCase();
      final sessionDate = (data['sessionDate'] ?? "").toString().toLowerCase();
      final sessionTime = (data['sessionTime'] ?? "").toString().toLowerCase();

      final searchMatch = search.isEmpty ||
          subjectName.contains(search) ||
          sessionDate.contains(search) ||
          sessionTime.contains(search);
      final yearMatch = year.isEmpty || year == selectedYear;
      final termMatch = term.isEmpty || term == selectedTerm;

      return searchMatch && yearMatch && termMatch;
    }).toList();

    filtered.sort((a, b) {
      final ad = a.data() as Map<String, dynamic>? ?? {};
      final bd = b.data() as Map<String, dynamic>? ?? {};
      final at = ad['createdAt'];
      final bt = bd['createdAt'];

      final am = at is Timestamp ? at.millisecondsSinceEpoch : 0;
      final bm = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;

      return bm.compareTo(am);
    });

    return filtered;
  }

  int _presentCount() {
    return _lastVisibleStudents
        .where((doc) => attendanceMap[doc.id] == true)
        .length;
  }

  int _absentCount() {
    return _lastVisibleStudents.length - _presentCount();
  }

  void _markAllVisible(bool value) {
    setState(() {
      for (final doc in _lastVisibleStudents) {
        attendanceMap[doc.id] = value;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedTime = picked;
    });
  }

  Future<void> _addSubject() async {
    final nameController = TextEditingController();
    String dialogYear = selectedYear;
    String dialogTerm = selectedTerm;

    final messenger = ScaffoldMessenger.of(context); // ✅ الحل هنا

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.black,
              title: const Text(
                "إضافة مادة",
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "اسم المادة"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: dialogYear,
                      dropdownColor: AppColors.black,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "السنة"),
                      items: years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(
                                y,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() {
                          dialogYear = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: dialogTerm,
                      dropdownColor: AppColors.black,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "الترم"),
                      items: terms
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() {
                          dialogTerm = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(dialogCtx);

                    try {
                      await FirebaseService.firestore
                          .collection("subjects")
                          .add({
                        "name": name,
                        "title": name,
                        "year": dialogYear,
                        "term": dialogTerm,
                        "createdAt": FieldValue.serverTimestamp(),
                        "createdBy":
                            FirebaseService.auth.currentUser?.uid ?? "",
                      });

                      if (!mounted) return;

                      setState(() {
                        selectedYear = dialogYear;
                        selectedTerm = dialogTerm;
                        selectedSubjectId = null;
                        selectedSubjectName = "";
                        attendanceMap.clear();
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("تمت إضافة المادة ✅"),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Add Subject Error: $e");

                      if (!mounted) return;

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("حصل خطأ ❌"),
                        ),
                      );
                    }
                  },
                  child: const Text("حفظ"),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _saveSession() async {
    if (saving) return;

    if (selectedSubjectId == null || selectedSubjectName.isEmpty) {
      show("اختار المادة أولاً");
      return;
    }

    if (selectedSessionId.isEmpty) {
      show("اختار الحصة أولاً");
      return;
    }

    setState(() => saving = true);

    try {
      final usersSnap =
          await FirebaseService.firestore.collection(AppConstants.users).get();
      final filteredStudents = _filterStudents(usersSnap.docs);

      if (filteredStudents.isEmpty) {
        show("لا يوجد طلاب للحفظ");
        return;
      }

      final sessionRef =
          FirebaseService.firestore.collection("attendance_sessions").doc();
      final lectureDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final batch = FirebaseService.firestore.batch();

      int presentCount = 0;

      for (final doc in filteredStudents) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final isPresent = attendanceMap[doc.id] == true;

        if (isPresent) presentCount++;

        batch.set(sessionRef.collection("records").doc(doc.id), {
          "userId": doc.id,
          "name": (data['name'] ?? "").toString(),
          "phone": (data['phone'] ?? "").toString(),
          "email": (data['email'] ?? "").toString(),
          "year": (data['year'] ?? selectedYear).toString(),
          "term": (data['term'] ?? selectedTerm).toString(),
          "isVIP": data['isVIP'] == true,
          "blocked": data['blocked'] == true,
          "present": isPresent,
          "late": lateMode,
          "subjectId": selectedSubjectId,
          "subjectName": selectedSubjectName,
          "sessionId": selectedSessionId,
          "sessionName": selectedSessionName,
          "sessionDate": _formatDate(selectedDate),
          "sessionTime": _formatTime(selectedTime),
          "sessionDateTime": Timestamp.fromDate(lectureDateTime),
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      batch.set(sessionRef, {
        "year": selectedYear,
        "term": selectedTerm,
        "subjectId": selectedSubjectId,
        "subjectName": selectedSubjectName,
        "sessionId": selectedSessionId,
        "sessionName": selectedSessionName,
        "sessionDate": _formatDate(selectedDate),
        "sessionTime": _formatTime(selectedTime),
        "sessionDateTime": Timestamp.fromDate(lectureDateTime),
        "totalStudents": filteredStudents.length,
        "presentCount": presentCount,
        "absentCount": filteredStudents.length - presentCount,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": FirebaseService.auth.currentUser?.uid ?? "",
      });

      await batch.commit();

      await _loadAttendancePercentages();

      if (mounted) {
        setState(() {
          attendanceMap.clear();
        });
      }

      show("تم حفظ الجلسة والحضور ✅");

      if (mounted) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      debugPrint("Attendance Save Error: $e");
      show("حصل خطأ أثناء الحفظ ❌");
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _showSessionDetails(
    QueryDocumentSnapshot sessionDoc,
    Map<String, dynamic> sessionData,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            (sessionData['subjectName'] ?? sessionData['name'] ?? "")
                .toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: FutureBuilder<QuerySnapshot>(
              future: sessionDoc.reference.collection("records").get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "❌ خطأ في تحميل التفاصيل",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد سجلات",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final records = snapshot.data!.docs;

                records.sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>? ?? {};
                  final bd = b.data() as Map<String, dynamic>? ?? {};
                  final an = (ad['name'] ?? "").toString().toLowerCase();
                  final bn = (bd['name'] ?? "").toString().toLowerCase();
                  return an.compareTo(bn);
                });

                int presentCount = 0;
                for (var r in records) {
                  final d = r.data() as Map<String, dynamic>? ?? {};
                  if (d['present'] == true) presentCount++;
                }

                final total = records.length;
                final percent = total == 0 ? 0 : (presentCount / total) * 100;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "حضر: $presentCount",
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text(
                            "الإجمالي: $total",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "${percent.toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: percent >= 75
                                  ? Colors.green
                                  : percent >= 50
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final data =
                              record.data() as Map<String, dynamic>? ?? {};
                          final present = data['present'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: present
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  present ? Icons.check_circle : Icons.cancel,
                                  color: present ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (data['name'] ?? "").toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (data['phone'] ?? "").toString(),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                      Text(
                                        (data['email'] ?? "").toString(),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "إغلاق",
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAttendancePercentages() async {
    try {
      final sessionsSnap = await FirebaseService.firestore
          .collection("attendance_sessions")
          .get();

      final Map<String, int> presentCount = {};
      final Map<String, int> totalCount = {};

      final List<Future<QuerySnapshot>> futures = [];

      for (final session in sessionsSnap.docs) {
        futures.add(session.reference.collection("records").get());
      }

      if (futures.isEmpty) {
        if (!mounted) return;
        setState(() {
          attendancePercentageCache.clear();
        });
        return;
      }

      final allRecords = await Future.wait(futures);

      for (final recordsSnap in allRecords) {
        for (final rec in recordsSnap.docs) {
          final data = rec.data() as Map<String, dynamic>? ?? {};
          final uid = (data['userId'] ?? "").toString().trim();
          if (uid.isEmpty) continue;

          totalCount[uid] = (totalCount[uid] ?? 0) + 1;

          if (data['present'] == true) {
            presentCount[uid] = (presentCount[uid] ?? 0) + 1;
          }
        }
      }

      final Map<String, double> result = {};

      totalCount.forEach((uid, total) {
        final present = presentCount[uid] ?? 0;
        result[uid] = total == 0 ? 0 : (present / total) * 100;
      });

      if (!mounted) return;

      setState(() {
        attendancePercentageCache.clear();
        attendancePercentageCache.addAll(result);
      });
    } catch (e) {
      debugPrint("Attendance % Error: $e");
    }
  }

  Widget _buildYearTermSubjectPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedYear,
                  dropdownColor: AppColors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "السنة"),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedYear = val;
                      selectedSubjectId = null;
                      selectedSubjectName = "";
                      attendanceMap.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedTerm,
                  dropdownColor: AppColors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "الترم"),
                  items: terms
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedTerm = val;
                      selectedSubjectId = null;
                      selectedSubjectName = "";
                      attendanceMap.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseService.firestore.collection("subjects").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  "❌ خطأ في تحميل المواد",
                  style: TextStyle(color: Colors.red),
                );
              }

              final allSubjects = snapshot.hasData ? snapshot.data!.docs : [];

              final filteredSubjects = allSubjects.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final year = (data['year'] ?? "").toString().trim();
                final term = (data['term'] ?? "").toString().trim();
                return year == selectedYear && term == selectedTerm;
              }).toList();

              if (filteredSubjects.isEmpty) {
                selectedSubjectId = null;
                selectedSubjectName = "";

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        "لا يوجد مواد حالياً",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("إضافة مادة"),
                    ),
                  ],
                );
              }

              final availableIds = filteredSubjects.map((e) => e.id).toSet();

              final currentSubjectId = availableIds.contains(selectedSubjectId)
                  ? selectedSubjectId
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: currentSubjectId,
                dropdownColor: AppColors.black,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "اختر المادة"),
                items: filteredSubjects.map((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final name = (data['name'] ?? data['title'] ?? "").toString();
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child:
                        Text(name, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  final selected =
                      filteredSubjects.firstWhere((e) => e.id == val);
                  final data = selected.data() as Map<String, dynamic>? ?? {};
                  final subjectId = selected.id;
                  final subjectName =
                      (data['name'] ?? data['title'] ?? "").toString();

                  setState(() {
                    selectedSubjectId = subjectId;
                    selectedSubjectName = subjectName;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectSessionsPage(
                        subjectId: subjectId,
                        subjectName: subjectName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildYearTermSubjectPanel(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedSubjectName.isEmpty
                      ? "اختر مادة لبدء تسجيل الحضور"
                      : "المادة الحالية: $selectedSubjectName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallBadge("السنة: $selectedYear", Colors.blue),
                    _smallBadge("الترم: $selectedTerm", Colors.purple),
                    _smallBadge(
                        "التاريخ: ${_formatDate(selectedDate)}", Colors.orange),
                    _smallBadge(
                        "الوقت: ${_formatTime(selectedTime)}", Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _addSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("إضافة مادة"),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_formatDate(selectedDate)),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _pickTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_formatTime(selectedTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () => _markAllVisible(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withValues(alpha: 0.18),
                        foregroundColor: Colors.green,
                      ),
                      child: const Text("الكل حاضر"),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () => _markAllVisible(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.18),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("مسح العلامات"),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _saveSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("حفظ الجلسة"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "ابحث بالاسم أو الموبايل أو الإيميل...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => studentSearch = val),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _smallBadge("حاضر: ${_presentCount()}", Colors.green),
              const SizedBox(width: 8),
              _smallBadge("غائب: ${_absentCount()}", Colors.red),
              const SizedBox(width: 8),
              _smallBadge(
                  "المعروض: ${_lastVisibleStudents.length}", Colors.blue),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection(AppConstants.users)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "❌ خطأ في تحميل الطلاب",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "لا يوجد طلاب",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final filtered = _filterStudents(snapshot.data!.docs);
              _lastVisibleStudents = filtered;

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    "لم نجد طلاباً لهذا البحث",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final name = (data['name'] ?? "Student").toString();
                  final phone = (data['phone'] ?? "").toString();
                  final email = (data['email'] ?? "").toString();
                  final year = (data['year'] ?? "").toString();
                  final term = (data['term'] ?? "").toString();
                  final vip = data['isVIP'] == true;
                  final blocked = data['blocked'] == true;
                  final linked =
                      data['linked'] == true || data['linkedByAdmin'] == true;
                  final present = attendanceMap[doc.id] == true;
                  final percent = attendancePercentageCache[doc.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: present ? Colors.green : Colors.white10,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (!mounted) return;
                        setState(() {
                          attendanceMap[doc.id] = !present;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: present,
                            onChanged: (val) {
                              if (!mounted) return;
                              setState(() {
                                attendanceMap[doc.id] = val == true;
                              });
                            },
                            activeColor: AppColors.gold,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "نسبة الحضور: ${percent.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    color: percent >= 75
                                        ? Colors.green
                                        : percent >= 50
                                            ? Colors.orange
                                            : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone.isNotEmpty ? phone : "لا يوجد رقم",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  email.isNotEmpty ? email : "لا يوجد إيميل",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (year.isNotEmpty)
                                      _smallBadge(year, Colors.blue),
                                    if (term.isNotEmpty)
                                      _smallBadge(term, Colors.purple),
                                    if (vip) _smallBadge("VIP", Colors.green),
                                    if (linked)
                                      _smallBadge("LINKED", Colors.orange),
                                    if (blocked)
                                      _smallBadge("BLOCKED", Colors.red),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Icon(
                                present
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: present ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                present ? "حاضر" : "غائب",
                                style: TextStyle(
                                  color: present ? Colors.green : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _smallBadge("حاضر: ${_presentCount()}", Colors.green),
              const SizedBox(width: 8),
              _smallBadge("غائب: ${_absentCount()}", Colors.red),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث بالمادة أو التاريخ...",
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
            onChanged: (val) => setState(() => reportSearch = val),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildYearTermSubjectPanel(),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection("attendance_sessions")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "❌ خطأ في تحميل الجلسات",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "لا توجد جلسات حضور بعد",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final filtered = _filterSessions(snapshot.data!.docs);

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    "لم نجد جلسات لهذا البحث",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final subjectName =
                      (data['subjectName'] ?? data['name'] ?? "").toString();
                  final sessionDate = (data['sessionDate'] ?? "").toString();
                  final sessionTime = (data['sessionTime'] ?? "").toString();
                  final total = data['totalStudents'] ?? 0;
                  final present = data['presentCount'] ?? 0;
                  final absent = data['absentCount'] ?? 0;
                  final subjectId = (data['subjectId'] ?? "").toString();

                  final double percent =
                      total == 0 ? 0 : (present / total) * 100;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        subjectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$selectedYear • $selectedTerm",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$sessionDate • $sessionTime",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "حضر $present | غاب $absent | الإجمالي $total",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "نسبة الحضور: ${percent.toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: percent >= 75
                                    ? Colors.green
                                    : percent >= 50
                                        ? Colors.orange
                                        : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onTap: () {
                        _showSessionDetails(doc, data);
                      },
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectSessionsPage(
                              subjectId: subjectId,
                              subjectName: subjectName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _smallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          selectedSubjectName.isEmpty
              ? "📊 تقارير الحضور"
              : "📊 $selectedSubjectName",
          style: const TextStyle(color: AppColors.gold),
        ),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "تسجيل الحضور"),
            Tab(text: "التقارير"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      (selectedSubjectId == null || selectedSubjectId!.isEmpty)
                          ? null
                          : FirebaseService.firestore
                              .collection("attendance_sessions")
                              .where("subjectId", isEqualTo: selectedSubjectId)
                              .orderBy("createdAt", descending: true)
                              .snapshots(),
                  builder: (context, snapshot) {
                    if (selectedSubjectId == null ||
                        selectedSubjectId!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child:
                              CircularProgressIndicator(color: AppColors.gold),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        "❌ خطأ في تحميل الحصص",
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "لا يوجد حصص لهذه المادة",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    final sessions = snapshot.data!.docs;

                    final currentSessionId =
                        sessions.any((e) => e.id == selectedSessionId)
                            ? selectedSessionId
                            : null;

                    if (currentSessionId == null && sessions.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final first = sessions.first;
                        final data =
                            first.data() as Map<String, dynamic>? ?? {};
                        setState(() {
                          selectedSessionId = first.id;
                          selectedSessionName =
                              (data['sessionName'] ?? data['name'] ?? "")
                                  .toString();
                        });
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: currentSessionId,
                      dropdownColor: Colors.black,
                      decoration: InputDecoration(
                        hintText: "اختار الحصة",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: sessions.map((e) {
                        final data = e.data() as Map<String, dynamic>? ?? {};
                        final name = (data['sessionName'] ?? data['name'] ?? "")
                            .toString();
                        final date = (data['date'] ?? data['sessionDate'] ?? "")
                            .toString();
                        return DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            date.isEmpty ? name : "$name • $date",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final selected =
                            sessions.firstWhere((e) => e.id == val);
                        final data =
                            selected.data() as Map<String, dynamic>? ?? {};
                        if (!mounted) return;
                        setState(() {
                          selectedSessionId = selected.id;
                          selectedSessionName =
                              (data['sessionName'] ?? data['name'] ?? "")
                                  .toString();
                        });
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttendanceTab(),
                    _buildReportsTab(),
                  ],
                ),
              ),
            ],
          ),
          if (saving)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
