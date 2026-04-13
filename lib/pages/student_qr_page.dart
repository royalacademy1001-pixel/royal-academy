import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/firebase_service.dart';
import '../core/colors.dart';

class StudentQRPage extends StatefulWidget {
  const StudentQRPage({super.key});

  @override
  State<StudentQRPage> createState() => _StudentQRPageState();
}

class _StudentQRPageState extends State<StudentQRPage> {

  String qrData = "";
  String userName = "";
  bool loading = true;
  bool blocked = false;

  @override
  void initState() {
    super.initState();
    generateQR();
  }

  Future<void> generateQR() async {
    try {
      final user = FirebaseService.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return;
      }

      final doc = await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null && data['blocked'] == true) {
        if (mounted) {
          setState(() {
            blocked = true;
            loading = false;
          });
        }
        return;
      }

      final name = (data?['name'] ?? user.email ?? "Student").toString();

      final qrMap = {
        "type": "student",
        "userId": user.uid,
        "name": name,
        "ts": DateTime.now().millisecondsSinceEpoch,
      };

      if (!mounted) return;

      setState(() {
        qrData = jsonEncode(qrMap);
        userName = name;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget _buildQR() {
    if (loading) {
      return const CircularProgressIndicator(color: AppColors.gold);
    }

    if (blocked) {
      return const Text(
        "❌ حسابك موقوف",
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    if (qrData.isEmpty) {
      return const Text(
        "حدث خطأ في توليد QR",
        style: TextStyle(color: Colors.white),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(
          data: qrData,
          size: 260,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 20),
        Text(
          userName,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "اعرض الكود للإدارة لتسجيل الحضور",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: generateQR,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.refresh, color: Colors.black),
          label: const Text(
            "تحديث QR",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          "📱 QR الخاص بك",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildQR(),
        ),
      ),
    );
  }
}