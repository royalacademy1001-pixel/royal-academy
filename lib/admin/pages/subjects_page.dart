import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import 'subject_sessions_page.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final nameController = TextEditingController();

  String selectedYear = "سنة أولى";
  String selectedTerm = "ترم أول";

  final List<String> years = ["سنة أولى", "سنة تانية"];
  final List<String> terms = ["ترم أول", "ترم تاني"];

  String? editingId;

  Future<void> addSubject() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    if (editingId != null) {
      await FirebaseService.firestore.collection("subjects").doc(editingId).update({
        "name": name,
        "title": name,
        "year": selectedYear,
        "term": selectedTerm,
      });
    } else {
      await FirebaseService.firestore.collection("subjects").add({
        "name": name,
        "title": name,
        "year": selectedYear,
        "term": selectedTerm,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    nameController.clear();
    editingId = null;

    if (mounted) Navigator.pop(context);
  }

  void openDialog({Map<String, dynamic>? data, String? id}) {
    if (data != null) {
      nameController.text = (data['name'] ?? "").toString();
      selectedYear = (data['year'] ?? selectedYear).toString();
      selectedTerm = (data['term'] ?? selectedTerm).toString();
      editingId = id;
    } else {
      nameController.clear();
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
                editingId != null ? "تعديل مادة" : "إضافة مادة",
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "اسم المادة"),
                  ),
                  DropdownButtonFormField(
                    initialValue: selectedYear,
                    dropdownColor: Colors.black,
                    items: years.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setStateDialog(() {
                        selectedYear = v;
                      });
                    },
                  ),
                  DropdownButtonFormField(
                    initialValue: selectedTerm,
                    dropdownColor: Colors.black,
                    items: terms.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setStateDialog(() {
                        selectedTerm = v;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                ElevatedButton(onPressed: addSubject, child: const Text("حفظ")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteSubject(String id) async {
    await FirebaseService.firestore.collection("subjects").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إدارة المواد"),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore.collection("subjects").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("لا توجد مواد", style: TextStyle(color: Colors.white)),
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
                        builder: (_) => SubjectSessionsPage(
                          subjectId: docs[i].id,
                          subjectName: (data['name'] ?? "").toString(),
                        ),
                      ),
                    );
                  },
                  title: Text(
                    (data['name'] ?? "").toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${data['year'] ?? ""} - ${data['term'] ?? ""}",
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
                        onPressed: () => deleteSubject(docs[i].id),
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