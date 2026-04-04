// 🔥 FINAL VERIFY CERTIFICATE PAGE (PRO MAX++ UPGRADE SAFE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// 🔥 Core
import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class VerifyCertificatePage extends StatelessWidget {
  final String certId;

  const VerifyCertificatePage({
    super.key,
    required this.certId,
  });

  @override
  Widget build(BuildContext context) {

    final String id = certId.trim();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "🔍 التحقق من الشهادة",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),

      body: id.isEmpty
          ? _invalidView(context, "❌ لا يوجد رقم شهادة")
          : FutureBuilder<Map<String, dynamic>?>(
              future: _loadCertificate(id),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _invalidView(context, "❌ خطأ في الاتصال");
                }

                final data = snapshot.data;

                if (data == null) {
                  return _invalidView(context, "❌ الشهادة غير موجودة");
                }

                return _validView(
                  context,
                  (data['name'] ?? "Unknown").toString(),
                  (data['course'] ?? "Course").toString(),
                  (data['date'] ?? "").toString(),
                  (data['certId'] ?? "").toString(),
                );
              },
            ),
    );
  }

  // ================= 🔥 LOAD =================
  Future<Map<String, dynamic>?> _loadCertificate(String id) async {
    try {

      /// 🔥 1. direct doc (الأسرع)
      final doc = await FirebaseService.firestore
          .collection("certificates")
          .doc(id)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      /// 🔥 2. fallback (شغلك القديم)
      final query = await FirebaseService.firestore
          .collection("certificates")
          .where("certId", isEqualTo: id)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }

      return null;

    } catch (e) {
      print("🔥 VERIFY ERROR: $e");
      return null;
    }
  }

  // ================= ✅ VALID =================
  Widget _validView(
      BuildContext context,
      String name,
      String course,
      String date,
      String id) {

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.25),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Icon(Icons.verified, color: Colors.green, size: 85),

            const SizedBox(height: 15),

            const Text(
              "الشهادة صحيحة 100% ✅",
              style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text("👤 $name",
                style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 6),

            Text("📚 $course",
                style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 6),

            Text("📅 $date",
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            Text(
              "🆔 $id",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            /// 🔥 COPY BUTTON
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ رقم الشهادة ✅")),
                );
              },
              child: const Text("📋 نسخ ID"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ❌ INVALID =================
  Widget _invalidView(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(Icons.cancel, color: Colors.red, size: 85),

          const SizedBox(height: 15),

          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("⬅ رجوع"),
          ),
        ],
      ),
    );
  }
}