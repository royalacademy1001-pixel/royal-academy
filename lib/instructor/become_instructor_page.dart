// 🔥 BECOME INSTRUCTOR PAGE (2026 ULTRA UI)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/colors.dart';

class BecomeInstructorPage extends StatefulWidget {
  const BecomeInstructorPage({super.key});

  @override
  State<BecomeInstructorPage> createState() =>
      _BecomeInstructorPageState();
}

class _BecomeInstructorPageState
    extends State<BecomeInstructorPage> {

  bool loading = true;
  bool sending = false;

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future loadUser() async {
    try {
      userData = await FirebaseService.getUserData();
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  Future sendRequest() async {

    if (sending) return;

    setState(() => sending = true);

    try {

      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .set({
        "instructorRequest": true,
      }, SetOptions(merge: true));

      showSnack("تم إرسال الطلب بنجاح ✅");

      await loadUser();

    } catch (_) {
      showSnack("حدث خطأ ❌", color: Colors.red);
    }

    if (mounted) setState(() => sending = false);
  }

  void showSnack(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool isAdmin = userData['isAdmin'] == true;
    bool approved = userData['instructorApproved'] == true;
    bool requested = userData['instructorRequest'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("👨‍🏫 كن مدرسًا",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: AppColors.premiumCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.workspace_premium,
                  size: 60, color: AppColors.gold),

              const SizedBox(height: 20),

              if (isAdmin)
                const Text(
                  "أنت أدمن بالفعل 👑",
                  style: TextStyle(color: Colors.white),
                ),

              if (!isAdmin && approved)
                const Text(
                  "أنت مدرس بالفعل 🎉",
                  style: TextStyle(color: Colors.green),
                ),

              if (!isAdmin && !approved && requested)
                const Text(
                  "طلبك قيد المراجعة ⏳",
                  style: TextStyle(color: Colors.orange),
                ),

              if (!isAdmin && !approved && !requested)
                Column(
                  children: [

                    const Text(
                      "ابدأ رحلتك كمدرس الآن 🚀",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 15),

                    sending
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: AppColors.goldButton,
                            onPressed: sendRequest,
                            child: const Text("📩 إرسال الطلب"),
                          ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}