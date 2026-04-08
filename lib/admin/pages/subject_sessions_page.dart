import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import 'attendance_take_page.dart';

class SubjectSessionsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectSessionsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectSessionsPage> createState() => _SubjectSessionsPageState();
}

class _SubjectSessionsPageState extends State<SubjectSessionsPage> {
  final nameController = TextEditingController();
  final timeController = TextEditingController();
  final durationController = TextEditingController();
  final notesController = TextEditingController();
  final instructorController = TextEditingController();

  DateTime? selectedDate;

  String selectedType = "شرح";
  String selectedStatus = "لم تتم";

  String? editingId;

  final List<String> types = ["شرح", "مراجعة", "امتحان"];
  final List<String> statusList = ["لم تتم", "تمت"];

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> saveSession() async {
    final name = nameController.text.trim();

    if (name.isEmpty || selectedDate == null) return;

    final data = {
      "subjectId": widget.subjectId,
      "subjectName": widget.subjectName,
      "name": name,
      "date": selectedDate!.toIso8601String(),
      "time": timeController.text.trim(),
      "duration": durationController.text.trim(),
      "type": selectedType,
      "notes": notesController.text.trim(),
      "instructor": instructorController.text.trim(),
      "status": selectedStatus,
      "createdAt": FieldValue.serverTimestamp(),
    };

    DocumentReference docRef;

    if (editingId != null) {
      docRef = FirebaseService.firestore.collection("sessions").doc(editingId);
      await docRef.update(data);
    } else {
      docRef = await FirebaseService.firestore.collection("sessions").add(data);
    }

    await FirebaseService.firestore
        .collection("attendance_sessions")
        .doc(docRef.id)
        .set({
      "sessionId": docRef.id,
      "subjectId": widget.subjectId,
      "subjectName": widget.subjectName,
      "name": name,
      "date": selectedDate!.toIso8601String(),
      "createdAt": FieldValue.serverTimestamp(),
      "totalStudents": 0,
      "presentCount": 0,
      "absentCount": 0,
    }, SetOptions(merge: true));

    nameController.clear();
    timeController.clear();
    durationController.clear();
    notesController.clear();
    instructorController.clear();
    selectedDate = null;
    editingId = null;

    if (mounted) Navigator.pop(context);
  }

  void openDialog({Map<String, dynamic>? data, String? id}) {
    if (data != null) {
      nameController.text = (data['name'] ?? "").toString();
      timeController.text = (data['time'] ?? "").toString();
      durationController.text = (data['duration'] ?? "").toString();
      notesController.text = (data['notes'] ?? "").toString();
      instructorController.text = (data['instructor'] ?? "").toString();
      selectedType = (data['type'] ?? selectedType).toString();
      selectedStatus = (data['status'] ?? selectedStatus).toString();

      final d = data['date'];
      if (d != null) {
        selectedDate = DateTime.tryParse(d.toString());
      }

      editingId = id;
    } else {
      nameController.clear();
      timeController.clear();
      durationController.clear();
      notesController.clear();
      instructorController.clear();
      selectedDate = null;
      editingId = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.black,
              title: Text(
                editingId != null ? "تعديل الحصة" : "إضافة حصة",
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "اسم الحصة"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      },
                      child: Text(
                        selectedDate == null
                            ? "اختار التاريخ"
                            : selectedDate!.toString().split(" ")[0],
                      ),
                    ),
                    TextField(
                      controller: timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "الوقت"),
                    ),
                    TextField(
                      controller: durationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "المدة"),
                    ),
                    DropdownButtonFormField(
                      initialValue: selectedType,
                      dropdownColor: Colors.black,
                      items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() {
                          selectedType = v;
                        });
                      },
                    ),
                    DropdownButtonFormField(
                      initialValue: selectedStatus,
                      dropdownColor: Colors.black,
                      items: statusList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() {
                          selectedStatus = v;
                        });
                      },
                    ),
                    TextField(
                      controller: instructorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "المحاضر"),
                    ),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "ملاحظات"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                ElevatedButton(onPressed: saveSession, child: const Text("حفظ")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteSession(String id) async {
    await FirebaseService.firestore.collection("sessions").doc(id).delete();
    await FirebaseService.firestore.collection("attendance_sessions").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("sessions")
            .where("subjectId", isEqualTo: widget.subjectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("لا توجد حصص", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>? ?? {};

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceTakePage(
                          sessionId: docs[i].id,
                          sessionName: (data['name'] ?? "").toString(),
                          subjectId: widget.subjectId,
                          subjectName: widget.subjectName,
                        ),
                      ),
                    );
                  },
                  title: Text(
                    (data['name'] ?? "").toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${data['date'] ?? ""} • ${data['type'] ?? ""}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openDialog(data: data, id: docs[i].id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteSession(docs[i].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}