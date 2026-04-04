import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class InstructorRequestsAdminPage extends StatefulWidget {
  const InstructorRequestsAdminPage({super.key});

  @override
  State<InstructorRequestsAdminPage> createState() =>
      _InstructorRequestsAdminPageState();
}

class _InstructorRequestsAdminPageState
    extends State<InstructorRequestsAdminPage> {

  bool loadingAction = false;

  void show(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<bool> confirm(String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future runAction(Future Function() action) async {
    if (loadingAction) return;

    setState(() => loadingAction = true);

    try {
      await action();
    } catch (e) {
      debugPrint("Instructor Action Error: $e");
      show("حصل خطأ ❌", color: Colors.red);
    }

    if (mounted) {
      setState(() => loadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📩 طلبات المدرسين",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Stack(
        children: [

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection("users")
                .where("instructorRequest", isEqualTo: true)
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>? ?? {};
                return (data['instructorApproved'] ?? false) == false;
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text("لا يوجد طلبات",
                      style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: users.length,
                itemBuilder: (context, index) {

                  var doc = users[index];
                  var data =
                      doc.data() as Map<String, dynamic>? ?? {};

                  String name = data['name'] ?? "بدون اسم";
                  String email = data['email'] ?? "No Email";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: AppColors.premiumCard,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            )),

                        const SizedBox(height: 5),

                        Text(email,
                            style: const TextStyle(
                              color: Colors.grey,
                            )),

                        const SizedBox(height: 10),

                        Row(
                          children: [

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {

                                  if (loadingAction) return;

                                  bool ok = await confirm("قبول المدرس؟");
                                  if (!ok) return;

                                  await runAction(() async {
                                    await doc.reference.set({
                                      "instructorApproved": true,
                                      "instructorRequest": false,
                                    }, SetOptions(merge: true));

                                    show("تم قبول المدرس ✅");
                                  });
                                },
                                child: const Text("قبول"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {

                                  if (loadingAction) return;

                                  bool ok = await confirm("رفض الطلب؟");
                                  if (!ok) return;

                                  await runAction(() async {
                                    await doc.reference.set({
                                      "instructorApproved": false,
                                      "instructorRequest": false,
                                    }, SetOptions(merge: true));

                                    show("تم الرفض ❌", color: Colors.red);
                                  });
                                },
                                child: const Text("رفض"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          if (loadingAction)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}