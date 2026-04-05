import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

import 'student_results_full_page.dart';

class StudentsCRMPage extends StatefulWidget {
  const StudentsCRMPage({super.key});

  @override
  State<StudentsCRMPage> createState() => _StudentsCRMPageState();
}

class _StudentsCRMPageState extends State<StudentsCRMPage> {

  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "📊 CRM الطلاب",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "🔍 بحث...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() => search = val);
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.users)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }

                var users = snapshot.data!.docs;

                var filtered = users.where((u) {
                  var data = u.data() as Map<String, dynamic>;

                  String name = (data['name'] ?? "").toLowerCase();
                  String email = (data['email'] ?? "").toLowerCase();

                  return search.isEmpty ||
                      name.contains(search.toLowerCase()) ||
                      email.contains(search.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {

                    var u = filtered[index];
                    var data = u.data() as Map<String, dynamic>;

                    int courses =
                        (data['enrolledCourses'] ?? []).length;

                    bool vip = data['isVIP'] ?? false;
                    bool blocked = data['blocked'] ?? false;

                    return Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(12),
                      decoration: AppColors.premiumCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            data['name'] ?? "Student",
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            data['email'] ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _badge("📚 $courses", Colors.blue),
                              const SizedBox(width: 5),
                              if (vip) _badge("VIP", Colors.green),
                              if (blocked) _badge("BLOCK", Colors.red),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              _btn("حضور", Colors.orange, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentAttendancePage(userId: u.id),
                                  ),
                                );
                              }),

                              _btn("نتائج", Colors.green, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentResultsFullPage(userId: u.id),
                                  ),
                                );
                              }),

                              _btn("فلوس", Colors.amber, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentFinancePage(userId: u.id),
                                  ),
                                );
                              }),

                            ],
                          )
                        ],
                      ),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentAttendancePage extends StatelessWidget {
  final String userId;

  const StudentAttendancePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📅 الحضور")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("attendance")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              var d = data[i].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(d['qrCode'] ?? ""),
                subtitle: Text(d['date'] ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentFinancePage extends StatelessWidget {
  final String userId;

  const StudentFinancePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💰 الحسابات")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("payments")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              var d = data[i].data() as Map<String, dynamic>;

              return ListTile(
                title: Text("مدفوع: ${d['paid'] ?? 0}"),
                subtitle: Text("باقي: ${d['remaining'] ?? 0}"),
              );
            },
          );
        },
      ),
    );
  }
}