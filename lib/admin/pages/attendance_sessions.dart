import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';

class AttendanceSessionsPage extends StatefulWidget {
  const AttendanceSessionsPage({super.key});

  @override
  State<AttendanceSessionsPage> createState() => _AttendanceSessionsPageState();
}

class _AttendanceSessionsPageState extends State<AttendanceSessionsPage> {
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  bool loading = false;
  String search = "";

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  DateTime _safeDateTimeFromInputs() {
    final now = DateTime.now();
    final dateText = dateController.text.trim();
    final timeText = timeController.text.trim();

    DateTime datePart = DateTime(now.year, now.month, now.day);
    TimeOfDay timePart = TimeOfDay.fromDateTime(now);

    if (dateText.isNotEmpty) {
      final parsedDate = DateTime.tryParse(dateText);
      if (parsedDate != null) {
        datePart = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      }
    }

    if (timeText.isNotEmpty) {
      final parts = timeText.split(':');
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

  Future<bool> createSession() async {
    final sessionName = nameController.text.trim();
    if (sessionName.isEmpty) return false;

    if (loading) return false;

    setState(() => loading = true);

    try {
      final sessionDateTime = _safeDateTimeFromInputs();

      final date = dateController.text.trim().isEmpty
          ? "${sessionDateTime.year}-${sessionDateTime.month.toString().padLeft(2, '0')}-${sessionDateTime.day.toString().padLeft(2, '0')}"
          : dateController.text.trim();

      final time = timeController.text.trim().isEmpty
          ? "${sessionDateTime.hour.toString().padLeft(2, '0')}:${sessionDateTime.minute.toString().padLeft(2, '0')}"
          : timeController.text.trim();

      final sessionRef =
          FirebaseFirestore.instance.collection("attendance_sessions").doc();

      await sessionRef.set({
        "name": sessionName,
        "subjectName": sessionName,
        "date": date,
        "time": time,
        "sessionDate": date,
        "sessionTime": time,
        "sessionDateTime": Timestamp.fromDate(sessionDateTime),
        "year": "",
        "term": "",
        "subjectId": "",
        "totalStudents": 0,
        "presentCount": 0,
        "absentCount": 0,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": "",
      });

      nameController.clear();
      dateController.clear();
      timeController.clear();

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

  Future<void> updateSession(String id) async {
    final sessionName = nameController.text.trim();
    if (sessionName.isEmpty) return;

    setState(() => loading = true);

    try {
      final sessionDateTime = _safeDateTimeFromInputs();

      final date = dateController.text.trim().isEmpty
          ? "${sessionDateTime.year}-${sessionDateTime.month.toString().padLeft(2, '0')}-${sessionDateTime.day.toString().padLeft(2, '0')}"
          : dateController.text.trim();

      final time = timeController.text.trim().isEmpty
          ? "${sessionDateTime.hour.toString().padLeft(2, '0')}:${sessionDateTime.minute.toString().padLeft(2, '0')}"
          : timeController.text.trim();

      await FirebaseFirestore.instance
          .collection("attendance_sessions")
          .doc(id)
          .update({
        "name": sessionName,
        "subjectName": sessionName,
        "date": date,
        "time": time,
        "sessionDate": date,
        "sessionTime": time,
        "sessionDateTime": Timestamp.fromDate(sessionDateTime),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم التعديل ✅")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("خطأ ❌")),
        );
      }
    }

    if (mounted) setState(() => loading = false);
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
    } catch (_) {}
  }

  void openEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    nameController.text =
        (data['name'] ?? data['subjectName'] ?? "").toString();
    dateController.text =
        (data['date'] ?? data['sessionDate'] ?? "").toString();
    timeController.text =
        (data['time'] ?? data['sessionTime'] ?? "").toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: const Text(
            "تعديل المادة",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: dateController,
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: timeController,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await updateSession(doc.id);
                if (!mounted) return;
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  void openAddDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  decoration: const InputDecoration(
                    hintText: "اسم المادة",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: dateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "التاريخ YYYY-MM-DD",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: timeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "الوقت HH:MM",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);

                      final created = await createSession();

                      if (!mounted) return;

                      if (created) {
                        Navigator.pop(context);

                        messenger.showSnackBar(
                          const SnackBar(content: Text("تم الإنشاء ✅")),
                        );
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  Widget buildSessionItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final name = (data['name'] ?? data['subjectName'] ?? "بدون اسم").toString();
    final date = (data['date'] ?? data['sessionDate'] ?? "").toString();
    final time = (data['time'] ?? data['sessionTime'] ?? "").toString();
    final totalStudents = (data['totalStudents'] ?? 0).toString();
    final presentCount = (data['presentCount'] ?? 0).toString();
    final absentCount = (data['absentCount'] ?? 0).toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          const Icon(Icons.class_, color: Colors.white),
          const SizedBox(width: 10),
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
                  "$date - $time",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "الإجمالي: $totalStudents | الحضور: $presentCount | الغياب: $absentCount",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => openEditDialog(doc),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteSession(doc.id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مواد الحضور"),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: loading ? null : openAddDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() => search = value.toLowerCase().trim());
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث عن مادة...",
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
              stream: FirebaseFirestore.instance
                  .collection("attendance_sessions")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "❌ خطأ في تحميل المواد",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد مواد حالياً",
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

                  return search.isEmpty ||
                      name.contains(search) ||
                      date.contains(search) ||
                      time.contains(search);
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
