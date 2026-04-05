// 🔥 QR ATTENDANCE SYSTEM (SCAN + SAVE)

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 CORE
import '../core/firebase_service.dart';
import '../core/colors.dart';

class QRAttendancePage extends StatefulWidget {
  const QRAttendancePage({super.key});

  @override
  State<QRAttendancePage> createState() => _QRAttendancePageState();
}

class _QRAttendancePageState extends State<QRAttendancePage> {

  final MobileScannerController scannerController = MobileScannerController();
  bool scanned = false;
  bool loading = false;
  String lastCode = "";
  String errorMessage = "";

  Future<void> handleScan(String code) async {

    if (scanned || loading) return;

    if (!mounted) return;

    setState(() {
      scanned = true;
      loading = true;
      lastCode = code;
      errorMessage = "";
    });

    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) {
        showSnack("لم يتم تسجيل الدخول ❌", color: Colors.red);
        return;
      }

      await FirebaseService.firestore.collection("attendance").add({
        "userId": user.uid,
        "qrCode": code,
        "date": DateTime.now().toIso8601String(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showSnack("تم تسجيل الحضور ✅");

    } catch (e) {
      debugPrint("QR Error: $e");
      if (mounted) {
        setState(() {
          errorMessage = "فشل تسجيل الحضور";
        });
      }
      showSnack("فشل تسجيل الحضور ❌", color: Colors.red);
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        scanned = false;
        loading = false;
      });
    }
  }

  void showSnack(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.black,

      appBar: AppBar(
        title: const Text(
          "📷 تسجيل الحضور",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
      ),

      body: Stack(
        children: [

          MobileScanner(
            controller: scannerController,
            onDetect: (barcodeCapture) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  handleScan(code);
                }
              }
            },
            errorBuilder: (context, error) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "تعذر تشغيل الكاميرا\n$error",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          if (loading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            ),

          if (errorMessage.isNotEmpty)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          if (lastCode.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "QR: $lastCode",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}