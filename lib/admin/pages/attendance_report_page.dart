// 🔥 ATTENDANCE REPORT PRO MAX

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

// 🔥 CORE
import '../../core/firebase_service.dart';
import '../../core/colors.dart';

// 🔥 WIDGET
import '../../widgets/loading_widget.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() =>
      _AttendanceReportPageState();
}

class _AttendanceReportPageState
    extends State<AttendanceReportPage> {

  String search = "";

  Future<String> getUserName(String userId) async {
    try {
      var doc = await FirebaseService.firestore
          .collection("users")
          .doc(userId)
          .get();

      return doc.data()?['name'] ?? "Student";
    } catch (_) {
      return "Student";
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "📊 تقارير الحضور",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث بالاسم...",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.gold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => search = val.toLowerCase()),
            ),
          ),

          /// 📋 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection("attendance")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const LoadingWidget();
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا يوجد حضور",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    var d = docs[index];
                    var data =
                        d.data() as Map<String, dynamic>;

                    String userId = data['userId'] ?? "";
                    String qr = data['qrCode'] ?? "";

                    Timestamp? ts = data['timestamp'];

                    String date = ts != null
                        ? ts.toDate().toString()
                        : "";

                    return FutureBuilder<String>(
                      future: getUserName(userId),
                      builder: (context, snap) {

                        String name =
                            snap.data ?? "Loading...";

                        if (search.isNotEmpty &&
                            !name.toLowerCase().contains(search)) {
                          return const SizedBox();
                        }

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius:
                                BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.white10),
                          ),
                          child: Row(
                            children: [

                              const Icon(Icons.person,
                                  color: AppColors.gold),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "📅 $date",
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12),
                                    ),

                                    Text(
                                      "QR: $qr",
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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