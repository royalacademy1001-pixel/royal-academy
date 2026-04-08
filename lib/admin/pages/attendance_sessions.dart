import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';

class AttendanceSessionsPage extends StatefulWidget {
  const AttendanceSessionsPage({super.key});

  @override
  State<AttendanceSessionsPage> createState() => _AttendanceSessionsPageState();
}

class _AttendanceSessionsPageState extends State<AttendanceSessionsPage> {
  final TextEditingController searchController = TextEditingController();

  bool loading = false;
  String search = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _formatTime(DateTime date) {
    return "${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
  }

  DateTime _safeDateTimeFromInputs({
    required String dateText,
    required String timeText,
  }) {
    final now = DateTime.now();

    DateTime datePart = DateTime(now.year, now.month, now.day);
    TimeOfDay timePart = TimeOfDay.fromDateTime(now);

    final trimmedDate = dateText.trim();
    final trimmedTime = timeText.trim();

    if (trimmedDate.isNotEmpty) {
      final parsedDate = DateTime.tryParse(trimmedDate);
      if (parsedDate != null) {
        datePart = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      } else {
        final parts = trimmedDate.split("-");
        if (parts.length == 3) {
          final year = int.tryParse(parts[0]) ?? now.year;
          final month = int.tryParse(parts[1]) ?? now.month;
          final day = int.tryParse(parts[2]) ?? now.day;
          datePart = DateTime(year, month, day);
        }
      }
    }

    if (trimmedTime.isNotEmpty) {
      final parts = trimmedTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? now.hour;
        final minute = int.tryParse(parts[1]) ?? now.minute;
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          timePart = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return DateTime(
      datePart.year,
      datePart.month,
      datePart.day,
      timePart.hour,
      timePart.minute,
    );
  }

  DateTime _extractSessionDateTime(Map<String, dynamic> data) {
    final raw = data['sessionDateTime'];
    if (raw is Timestamp) {
      return raw.toDate();
    }

    final dateText = (data['date'] ?? data['sessionDate'] ?? "").toString();
    final timeText = (data['time'] ?? data['sessionTime'] ?? "").toString();
    return _safeDateTimeFromInputs(dateText: dateText, timeText: timeText);
  }

  String _sessionStatus(DateTime sessionDateTime) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (sessionDateTime.isAfter(todayEnd)) return "قادمة";
    if (sessionDateTime.isBefore(todayStart)) return "منتهية";
    return "اليوم";
  }

  Color _statusColor(String status) {
    switch (status) {
      case "قادمة":
        return Colors.blueAccent;
      case "اليوم":
        return Colors.greenAccent;
      case "منتهية":
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDateTime,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.black,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.black,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<bool> createSession({
    required String sessionName,
    required String dateText,
    required String timeText,
    String year = "",
    String term = "",
    String subjectId = "",
    String createdBy = "",
  }) async {
    final name = sessionName.trim();
    if (name.isEmpty) return false;

    if (loading) return false;

    setState(() => loading = true);

    try {
      final sessionDateTime = _safeDateTimeFromInputs(
        dateText: dateText,
        timeText: timeText,
      );

      final date = dateText.trim().isEmpty
          ? _formatDate(sessionDateTime)
          : dateText.trim();

      final time = timeText.trim().isEmpty
          ? _formatTime(sessionDateTime)
          : timeText.trim();

      final sessionRef =
          FirebaseFirestore.instance.collection("attendance_sessions").doc();

      await sessionRef.set({
        "name": name,
        "subjectName": name,
        "date": date,
        "time": time,
        "sessionDate": date,
        "sessionTime": time,
        "sessionDateTime": Timestamp.fromDate(sessionDateTime),
        "year": year,
        "term": term,
        "subjectId": subjectId,
        "totalStudents": 0,
        "presentCount": 0,
        "absentCount": 0,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": createdBy,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إضافة الحصة ✅")),
        );
      }

      return true;
    } catch (e) {
      debugPrint("Create Session Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حصل خطأ أثناء الإضافة ❌")),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<bool> updateSession({
    required String id,
    required String sessionName,
    required String dateText,
    required String timeText,
    String year = "",
    String term = "",
    String subjectId = "",
  }) async {
    final name = sessionName.trim();
    if (name.isEmpty) return false;

    if (loading) return false;

    setState(() => loading = true);

    try {
      final sessionDateTime = _safeDateTimeFromInputs(
        dateText: dateText,
        timeText: timeText,
      );

      final date = dateText.trim().isEmpty
          ? _formatDate(sessionDateTime)
          : dateText.trim();

      final time = timeText.trim().isEmpty
          ? _formatTime(sessionDateTime)
          : timeText.trim();

      await FirebaseFirestore.instance
          .collection("attendance_sessions")
          .doc(id)
          .update({
        "name": name,
        "subjectName": name,
        "date": date,
        "time": time,
        "sessionDate": date,
        "sessionTime": time,
        "sessionDateTime": Timestamp.fromDate(sessionDateTime),
        "year": year,
        "term": term,
        "subjectId": subjectId,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم التعديل ✅")),
        );
      }

      return true;
    } catch (e) {
      debugPrint("Update Session Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("خطأ أثناء التعديل ❌")),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection("attendance_sessions")
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم الحذف 🗑")),
        );
      }
    } catch (e) {
      debugPrint("Delete Session Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل الحذف ❌")),
        );
      }
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openSessionDialog({DocumentSnapshot? doc}) async {
    final data = doc?.data() as Map<String, dynamic>? ?? {};

    final TextEditingController nameController = TextEditingController(
      text: (data['name'] ?? data['subjectName'] ?? "").toString(),
    );
    final TextEditingController dateController = TextEditingController(
      text: (data['date'] ?? data['sessionDate'] ?? "").toString(),
    );
    final TextEditingController timeController = TextEditingController(
      text: (data['time'] ?? data['sessionTime'] ?? "").toString(),
    );
    final TextEditingController yearController = TextEditingController(
      text: (data['year'] ?? "").toString(),
    );
    final TextEditingController termController = TextEditingController(
      text: (data['term'] ?? "").toString(),
    );
    final TextEditingController subjectIdController = TextEditingController(
      text: (data['subjectId'] ?? "").toString(),
    );

    final bool isEdit = doc != null;
    DateTime previewDateTime = _extractSessionDateTime(data);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDateTime() async {
              final picked = await _pickDateTime(initialDateTime: previewDateTime);
              if (picked != null) {
                previewDateTime = picked;
                dateController.text = _formatDate(picked);
                timeController.text = _formatTime(picked);
                setDialogState(() {});
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.black,
              title: Text(
                isEdit ? "تعديل جلسة الحضور" : "إضافة جلسة حضور",
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "اسم المادة / الحصة",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "مثال: Anatomy / Biochemistry",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "التاريخ",
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "YYYY-MM-DD",
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: IconButton(
                          onPressed: pickDateTime,
                          icon: const Icon(Icons.calendar_month, color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "الوقت",
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "HH:MM",
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: IconButton(
                          onPressed: pickDateTime,
                          icon: const Icon(Icons.access_time, color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yearController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "الفرقة / السنة",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "مثال: Level 1",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: termController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "الترم",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "مثال: Term 1",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subjectIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Subject ID",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "اختياري",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "معاينة الوقت",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_formatDate(previewDateTime)}  |  ${_formatTime(previewDateTime)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "الحالة: ${_sessionStatus(previewDateTime)}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final dateText = dateController.text.trim();
                          final timeText = timeController.text.trim();
                          final year = yearController.text.trim();
                          final term = termController.text.trim();
                          final subjectId = subjectIdController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("اسم الحصة مطلوب")),
                            );
                            return;
                          }

                          bool success = false;

                          if (isEdit) {
                            success = await updateSession(
                              id: doc!.id,
                              sessionName: name,
                              dateText: dateText,
                              timeText: timeText,
                              year: year,
                              term: term,
                              subjectId: subjectId,
                            );
                          } else {
                            success = await createSession(
                              sessionName: name,
                              dateText: dateText,
                              timeText: timeText,
                              year: year,
                              term: term,
                              subjectId: subjectId,
                              createdBy: "",
                            );
                          }

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? "حفظ التعديلات" : "حفظ"),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    dateController.dispose();
    timeController.dispose();
    yearController.dispose();
    termController.dispose();
    subjectIdController.dispose();
  }

  Widget buildSessionItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final name = (data['name'] ?? data['subjectName'] ?? "بدون اسم").toString();
    final date = (data['date'] ?? data['sessionDate'] ?? "").toString();
    final time = (data['time'] ?? data['sessionTime'] ?? "").toString();
    final year = (data['year'] ?? "").toString();
    final term = (data['term'] ?? "").toString();
    final totalStudents = (data['totalStudents'] ?? 0).toString();
    final presentCount = (data['presentCount'] ?? 0).toString();
    final absentCount = (data['absentCount'] ?? 0).toString();

    final sessionDateTime = _extractSessionDateTime(data);
    final status = _sessionStatus(sessionDateTime);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.premiumCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "$date - $time",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (year.isNotEmpty || term.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${year.isNotEmpty ? year : ''}${year.isNotEmpty && term.isNotEmpty ? ' | ' : ''}${term.isNotEmpty ? term : ''}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  "الإجمالي: $totalStudents | الحضور: $presentCount | الغياب: $absentCount",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => openSessionDialog(doc: doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: AppColors.black,
                        title: const Text(
                          "تأكيد الحذف",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "هل تريد حذف هذه الجلسة نهائيًا؟",
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("إلغاء"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("حذف"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await deleteSession(doc.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() => search = value.toLowerCase().trim());
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "بحث عن حصة أو تاريخ أو وقت...",
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.black,
          prefixIcon: const Icon(Icons.search, color: AppColors.gold),
          suffixIcon: search.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => search = "");
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsQuery = FirebaseFirestore.instance
        .collection("attendance_sessions")
        .orderBy("sessionDateTime", descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("جلسات الحضور"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loading ? null : () => openSessionDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: loading ? null : () => openSessionDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          _topSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: sessionsQuery.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                int total = docs.length;
                int todayCount = 0;
                int upcomingCount = 0;
                int endedCount = 0;

                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final sessionDateTime = _extractSessionDateTime(data);

                  if (sessionDateTime.isAfter(todayEnd)) {
                    upcomingCount++;
                  } else if (sessionDateTime.isBefore(todayStart)) {
                    endedCount++;
                  } else {
                    todayCount++;
                  }
                }

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: [
                    _statCard(
                      title: "إجمالي الجلسات",
                      value: total.toString(),
                      icon: Icons.event_note_outlined,
                    ),
                    _statCard(
                      title: "جلسات اليوم",
                      value: todayCount.toString(),
                      icon: Icons.today_outlined,
                    ),
                    _statCard(
                      title: "جلسات قادمة",
                      value: upcomingCount.toString(),
                      icon: Icons.schedule_outlined,
                    ),
                    _statCard(
                      title: "جلسات منتهية",
                      value: endedCount.toString(),
                      icon: Icons.history_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: sessionsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                      "لا توجد جلسات حالياً",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final name = (data['name'] ?? data['subjectName'] ?? "")
                      .toString()
                      .toLowerCase();
                  final date = (data['date'] ?? data['sessionDate'] ?? "")
                      .toString()
                      .toLowerCase();
                  final time = (data['time'] ?? data['sessionTime'] ?? "")
                      .toString()
                      .toLowerCase();
                  final year = (data['year'] ?? "").toString().toLowerCase();
                  final term = (data['term'] ?? "").toString().toLowerCase();

                  return search.isEmpty ||
                      name.contains(search) ||
                      date.contains(search) ||
                      time.contains(search) ||
                      year.contains(search) ||
                      term.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد نتائج",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return buildSessionItem(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}