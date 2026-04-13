// 🔥 ADMIN QR GENERATOR PAGE (DYNAMIC + SECURE)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// 🔥 CORE
import '../core/colors.dart';

class AdminQRGeneratorPage extends StatefulWidget {
  const AdminQRGeneratorPage({super.key});

  @override
  State<AdminQRGeneratorPage> createState() => _AdminQRGeneratorPageState();
}

class _AdminQRGeneratorPageState extends State<AdminQRGeneratorPage> {

  final TextEditingController courseController = TextEditingController();
  final TextEditingController sessionController = TextEditingController();

  DateTime selectedTime = DateTime.now();
  int expiryMinutes = 2;

  String qrData = "";

  void generateQR() {

    if (courseController.text.trim().isEmpty || sessionController.text.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();

    final data = {
      "type": "attendance",
      "courseId": courseController.text.trim(),
      "sessionId": sessionController.text.trim(),
      "sessionStartAt": selectedTime.toIso8601String(),
      "expiresAt": now.add(Duration(minutes: expiryMinutes)).toIso8601String(),
      "graceMinutes": 10,
    };

    if (!mounted) return;

    setState(() {
      qrData = jsonEncode(data);
    });
  }

  Future<void> pickTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  void dispose() {
    courseController.dispose();
    sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.black,

      appBar: AppBar(
        title: const Text(
          "🎯 توليد QR الحضور",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            TextField(
              controller: courseController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Course ID",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: sessionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Session ID",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 15),

            ListTile(
              title: const Text("اختيار تاريخ المحاضرة",
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                selectedTime.toString(),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.white),
              onTap: pickTime,
            ),

            const SizedBox(height: 15),

            DropdownButton<int>(
              value: expiryMinutes,
              dropdownColor: Colors.black,
              items: [1,2,3,5,10]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text("$e دقيقة",
                    style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  expiryMinutes = v;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: generateQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
              ),
              child: const Text("توليد QR"),
            ),

            const SizedBox(height: 30),

            if (qrData.isNotEmpty)
              Column(
                children: [

                  QrImageView(
                    data: qrData,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "QR جاهز للمسح ✅",
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    qrData,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}