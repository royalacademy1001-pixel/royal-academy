import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class AttendanceTakePage extends StatefulWidget {
  const AttendanceTakePage({super.key});

  @override
  State<AttendanceTakePage> createState() => _AttendanceTakePageState();
}

class _AttendanceTakePageState extends State<AttendanceTakePage> {

  String search = "";

  String todayId() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<bool> alreadyMarked(String studentId) async {
    final doc = await FirebaseService.firestore
        .collection("attendance")
        .doc(todayId())
        .collection("students")
        .doc(studentId)
        .get();

    return doc.exists;
  }

  Future<void> markAttendance(String studentId, String name) async {

    final exists = await alreadyMarked(studentId);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم تسجيل الحضور مسبقًا لـ $name")),
      );
      return;
    }

    await FirebaseService.firestore
        .collection("attendance")
        .doc(todayId())
        .collection("students")
        .doc(studentId)
        .set({
      "name": name,
      "status": "present",
      "time": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تسجيل حضور $name")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("تسجيل الحضور"),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) {
                setState(() => search = v.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: "بحث عن طالب...",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection("users")
                  .where("role", isEqualTo: "student")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? "").toString().toLowerCase();
                  return name.contains(search);
                }).toList();

                if (students.isEmpty) {
                  return const Center(
                    child: Text("لا يوجد طلاب"),
                  );
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {

                    final data = students[index];
                    final name = data['name'] ?? "بدون اسم";
                    final id = data.id;

                    return FutureBuilder<bool>(
                      future: alreadyMarked(id),
                      builder: (context, snap) {

                        final marked = snap.data == true;

                        return Card(
                          color: Colors.black,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(

                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),

                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    marked ? Colors.grey : Colors.green,
                              ),
                              onPressed: marked
                                  ? null
                                  : () => markAttendance(id, name),
                              child: Text(marked ? "تم" : "حضور"),
                            ),
                          ),
                        );
                      },
                    );
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