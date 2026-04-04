// 🔥 FINAL ULTRA CERTIFICATE PAGE (PRO MAX++ FINAL STABLE SAFE)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

// 🔥 PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 🔥 Core
import 'core/firebase_service.dart';
import 'core/constants.dart';
import 'core/colors.dart';

class CertificatePage extends StatefulWidget {
  final String courseId;

  const CertificatePage({super.key, required this.courseId});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {

  bool saved = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("🏆 الشهادة",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          FirebaseService.firestore
              .collection(AppConstants.users)
              .doc(user.uid)
              .get(),
          FirebaseService.firestore
              .collection(AppConstants.courses)
              .doc(widget.courseId)
              .get(),
        ]),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.gold),
            );
          }

          final userDoc =
              snapshot.data![0] as DocumentSnapshot<Map<String, dynamic>>;
          final courseDoc =
              snapshot.data![1] as DocumentSnapshot<Map<String, dynamic>>;

          final userData = userDoc.data() ?? {};
          final courseData = courseDoc.data() ?? {};

          String name =
              (userData['name'] ??
              userData['email'] ??
              "Student").toString();

          String courseTitle =
              (courseData['title'] ?? "Course").toString();

          /// 🔥 FIX CERT ID (ثابت لكل مستخدم + كورس)
          String certId = "${user.uid}_${widget.courseId}";

          String date =
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          /// 🔥 SAVE ONCE ONLY
          if (!saved) {
            saved = true;

            FirebaseService.firestore
                .collection(AppConstants.certificates)
                .doc(certId)
                .set({
              "certId": certId,
              "name": name,
              "course": courseTitle,
              "date": date,
              "userId": user.uid,
              "courseId": widget.courseId,
              "createdAt": FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          String qrData =
              "https://royal-academy.app/verify/$certId";

          return SingleChildScrollView(
            child: Column(
              children: [

                _certificateUI(name, courseTitle, certId, date, qrData),

                const SizedBox(height: 20),

                loading
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          ElevatedButton(
                            onPressed: () =>
                                _downloadPDF(name, courseTitle, certId, date, qrData),
                            child: const Text("📥 تحميل"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () =>
                                _sharePDF(name, courseTitle, certId, date, qrData),
                            child: const Text("📤 مشاركة"),
                          ),
                        ],
                      ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _certificateUI(String name, String course, String id, String date, String qr) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFF1A1A1A), Colors.black],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: AppColors.goldShadow,
      ),
      child: Column(
        children: [
          const Text("🏆 Certificate of Completion",
              style: TextStyle(color: AppColors.gold, fontSize: 20)),
          const SizedBox(height: 15),
          Text(name,
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 10),
          Text(course,
              style: const TextStyle(color: AppColors.gold, fontSize: 18)),
          const SizedBox(height: 10),
          Text("Date: $date", style: const TextStyle(color: Colors.grey)),
          Text("ID: $id", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: QrImageView(data: qr, size: 100),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _buildPdf(
      String name, String course, String id, String date, String qr) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text("Certificate of Completion",
                    style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Text(name),
                pw.Text(course),
                pw.SizedBox(height: 10),
                pw.Text("Date: $date"),
                pw.Text("ID: $id"),
                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qr,
                  width: 100,
                  height: 100,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _downloadPDF(
      String name, String course, String id, String date, String qr) async {

    setState(() => loading = true);

    final pdf = await _buildPdf(name, course, id, date, qr);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/certificate_$id.pdf");

    await file.writeAsBytes(await pdf.save());

    setState(() => loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم الحفظ ✅")));
  }

  Future<void> _sharePDF(
      String name, String course, String id, String date, String qr) async {

    setState(() => loading = true);

    final pdf = await _buildPdf(name, course, id, date, qr);

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/certificate_$id.pdf");

    await file.writeAsBytes(await pdf.save());

    setState(() => loading = false);

    await Share.shareXFiles([XFile(file.path)]);
  }
}