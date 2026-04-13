// 🔥 QR ATTENDANCE SYSTEM (ADVANCED SCAN + SAVE + DUPLICATE PREVENTION + SYSTEM LINK)

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  String successMessage = "";

  Future<void> handleScan(String code) async {
    if (scanned || loading) return;
    if (!mounted) return;

    setState(() {
      scanned = true;
      loading = true;
      lastCode = code;
      errorMessage = "";
      successMessage = "";
    });

    try {
      final payloadJson = jsonDecode(code);

      if (payloadJson is Map && payloadJson['type'] == 'student') {
        final studentId = payloadJson['userId']?.toString() ?? "";

        if (studentId.isEmpty) {
          throw Exception("QR غير صحيح");
        }

        final attendanceDocId = _buildAttendanceDocId(
          userId: studentId,
          courseId: "manual",
          sessionId: null,
          rawCode: code,
        );

        final attendanceRef =
            FirebaseService.firestore.collection("attendance").doc(attendanceDocId);

        await FirebaseService.firestore.runTransaction((transaction) async {
          final existing = await transaction.get(attendanceRef);

          if (existing.exists) {
            throw Exception("ATTENDANCE_ALREADY_RECORDED");
          }

          final now = DateTime.now();

          transaction.set(attendanceRef, {
            "attendanceId": attendanceDocId,
            "userId": studentId,
            "userName": "",
            "userEmail": "",
            "userRole": "student",
            "courseId": "manual",
            "courseTitle": "",
            "sessionId": "",
            "sessionTitle": "",
            "qrType": "student",
            "qrCode": code,
            "status": "present",
            "scanMode": "admin_scan",
            "scanSource": "mobile_scanner",
            "createdAt": FieldValue.serverTimestamp(),
            "scanDate": now.toIso8601String(),
            "payload": payloadJson,
          });
        });

        if (!mounted) return;

        setState(() {
          successMessage = "تم تسجيل الحضور بنجاح ✅";
          errorMessage = "";
        });

        showSnack("تم تسجيل الحضور ✅", color: Colors.green);
      } else {
        final user = FirebaseService.auth.currentUser;
        if (user == null) {
          showSnack("لم يتم تسجيل الدخول ❌", color: Colors.red);
          return;
        }

        final payload = QRAttendancePayload.fromCode(code);

        if (payload.isExpired) {
          throw Exception("انتهت صلاحية QR");
        }

        if (payload.type.toLowerCase() != "attendance" &&
            payload.type.toLowerCase() != "legacy") {
          throw Exception("QR غير مخصص لتسجيل الحضور");
        }

        final userDoc = await FirebaseService.firestore
            .collection("users")
            .doc(user.uid)
            .get();

        final userData = userDoc.data();

        final userName = _extractUserName(userData, user.email);
        final userRole = _extractString(userData, [
          "role",
          "userRole",
          "accountType",
          "type",
        ]);

        final courseId = payload.courseId;
        final sessionId = payload.sessionId;

        if (courseId == null || courseId.isEmpty) {
          throw Exception("QR ناقص courseId");
        }

        final allowed = await _isAllowedForCourse(
          userId: user.uid,
          userRole: userRole,
          userData: userData,
          courseId: courseId,
        );

        if (!allowed) {
          throw Exception("أنت غير مسجل في هذا الكورس");
        }

        final attendanceDocId = _buildAttendanceDocId(
          userId: user.uid,
          courseId: courseId,
          sessionId: sessionId,
          rawCode: code,
        );

        final attendanceRef =
            FirebaseService.firestore.collection("attendance").doc(attendanceDocId);

        await FirebaseService.firestore.runTransaction((transaction) async {
          final existing = await transaction.get(attendanceRef);

          if (existing.exists) {
            throw Exception("ATTENDANCE_ALREADY_RECORDED");
          }

          final now = DateTime.now();
          final status = _computeStatus(
            sessionStartAt: payload.sessionStartAt,
            graceMinutes: payload.graceMinutes,
            now: now,
          );

          transaction.set(attendanceRef, {
            "attendanceId": attendanceDocId,
            "userId": user.uid,
            "userName": userName,
            "userEmail": user.email ?? "",
            "userRole": userRole.isEmpty ? "student" : userRole,
            "courseId": courseId,
            "courseTitle": payload.courseTitle ?? "",
            "sessionId": sessionId ?? "",
            "sessionTitle": payload.sessionTitle ?? "",
            "qrType": payload.type,
            "qrCode": code,
            "status": status,
            "scanMode": "qr",
            "scanSource": "mobile_scanner",
            "createdAt": FieldValue.serverTimestamp(),
            "scanDate": now.toIso8601String(),
            "payload": payload.rawData,
          });
        });

        if (!mounted) return;

        setState(() {
          successMessage = "تم تسجيل الحضور بنجاح ✅";
          errorMessage = "";
        });

        showSnack("تم تسجيل الحضور ✅", color: Colors.green);
      }
    } catch (e) {
      debugPrint("QR Error: $e");

      if (mounted) {
        final message = e.toString().replaceFirst("Exception: ", "");

        setState(() {
          if (message == "ATTENDANCE_ALREADY_RECORDED") {
            errorMessage = "تم تسجيل حضورك بالفعل ⚠️";
          } else {
            errorMessage = message.isNotEmpty
                ? message
                : "فشل تسجيل الحضور";
          }
        });

        if (message == "ATTENDANCE_ALREADY_RECORDED") {
          showSnack("تم تسجيل حضورك بالفعل ⚠️", color: Colors.orange);
        } else {
          showSnack("فشل تسجيل الحضور ❌", color: Colors.red);
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        scanned = false;
        loading = false;
      });
    }
  }

  String _computeStatus({
    DateTime? sessionStartAt,
    required int graceMinutes,
    required DateTime now,
  }) {
    if (sessionStartAt == null) return "present";
    final lateLimit = sessionStartAt.add(Duration(minutes: graceMinutes));
    if (now.isAfter(lateLimit)) return "late";
    return "present";
  }

  Future<bool> _isAllowedForCourse({
    required String userId,
    required String userRole,
    required Map<String, dynamic>? userData,
    required String courseId,
  }) async {
    final role = userRole.trim().toLowerCase();

    if (role == "admin" || role == "teacher" || role == "instructor") {
      return true;
    }

    if (userData == null) return true;

    final possibleKeys = [
      "enrolledCourses",
      "courseIds",
      "courses",
      "myCourses",
    ];

    for (final key in possibleKeys) {
      final value = userData[key];

      if (value is List) {
        if (value.map((e) => e.toString()).contains(courseId)) {
          return true;
        }
      }

      if (value is String && value.trim().isNotEmpty) {
        final parts = value.split(",").map((e) => e.trim()).toList();
        if (parts.contains(courseId)) {
          return true;
        }
      }
    }

    return true;
  }

  String _buildAttendanceDocId({
    required String userId,
    required String courseId,
    required String? sessionId,
    required String rawCode,
  }) {
    final safeUserId = _safeId(userId);
    final safeCourseId = _safeId(courseId);
    final safeSessionId = sessionId != null && sessionId.trim().isNotEmpty
        ? _safeId(sessionId)
        : _safeId(rawCode.hashCode.toUnsigned(32).toRadixString(36));

    return "${safeUserId}_$safeCourseId\_$safeSessionId";
  }

  String _safeId(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\/\\\.\#\$\[\]]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _extractUserName(Map<String, dynamic>? data, String? fallbackEmail) {
    if (data == null) {
      return fallbackEmail?.split("@").first ?? "طالب";
    }

    final name = _extractString(data, [
      "name",
      "fullName",
      "displayName",
      "username",
      "studentName",
      "userName",
    ]);

    if (name.isNotEmpty) return name;

    if (fallbackEmail != null && fallbackEmail.contains("@")) {
      return fallbackEmail.split("@").first;
    }

    return "طالب";
  }

  String _extractString(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return "";

    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }

    return "";
  }

  void showSnack(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = loading
        ? Colors.orange
        : (errorMessage.isNotEmpty ? Colors.red : AppColors.gold);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          "📷 تسجيل الحضور",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: AppColors.gold),
        actions: [
          IconButton(
            onPressed: () {
              scannerController.toggleTorch();
            },
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: "الفلاش",
          ),
          IconButton(
            onPressed: () {
              scannerController.switchCamera();
            },
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: "تبديل الكاميرا",
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (barcodeCapture) {
              final barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code =
                    barcodes.first.rawValue ?? barcodes.first.displayValue;
                if (code != null && code.trim().isNotEmpty) {
                  handleScan(code.trim());
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
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderColor, width: 4),
                          left: BorderSide(color: borderColor, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderColor, width: 4),
                          right: BorderSide(color: borderColor, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: borderColor, width: 4),
                          left: BorderSide(color: borderColor, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: borderColor, width: 4),
                          right: BorderSide(color: borderColor, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 18,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.35),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "وجّه الكاميرا نحو QR الحضور",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "يدعم QR بصيغة JSON أو كود نصي عادي",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 22,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (successMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      successMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (lastCode.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      "QR: $lastCode",
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (loading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.gold),
                        SizedBox(height: 10),
                        Text(
                          "جارٍ تسجيل الحضور...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QRAttendancePayload {
  final String rawCode;
  final String type;
  final String? courseId;
  final String? courseTitle;
  final String? sessionId;
  final String? sessionTitle;
  final DateTime? sessionStartAt;
  final DateTime? expiresAt;
  final int graceMinutes;
  final Map<String, dynamic> rawData;

  QRAttendancePayload({
    required this.rawCode,
    required this.type,
    required this.courseId,
    required this.courseTitle,
    required this.sessionId,
    required this.sessionTitle,
    required this.sessionStartAt,
    required this.expiresAt,
    required this.graceMinutes,
    required this.rawData,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory QRAttendancePayload.fromCode(String code) {
    Map<String, dynamic> decoded = {};
    String type = "legacy";
    String? courseId;
    String? courseTitle;
    String? sessionId;
    String? sessionTitle;
    DateTime? sessionStartAt;
    DateTime? expiresAt;
    int graceMinutes = 10;

    try {
      final dynamic result = jsonDecode(code);
      if (result is Map<String, dynamic>) {
        decoded = result;

        type = _readString(decoded, [
          "type",
          "qrType",
          "kind",
        ])?.trim().isNotEmpty ==
                true
            ? _readString(decoded, ["type", "qrType", "kind"])!.trim()
            : "attendance";

        courseId = _readString(decoded, [
          "courseId",
          "course_id",
          "course",
        ]);

        courseTitle = _readString(decoded, [
          "courseTitle",
          "course_name",
          "courseName",
        ]);

        sessionId = _readString(decoded, [
          "sessionId",
          "session_id",
          "lessonId",
          "lectureId",
        ]);

        sessionTitle = _readString(decoded, [
          "sessionTitle",
          "session_name",
          "lectureTitle",
          "lessonTitle",
        ]);

        sessionStartAt = _readDateTime(decoded, [
          "sessionStartAt",
          "startAt",
          "startsAt",
          "dateTime",
        ]);

        expiresAt = _readDateTime(decoded, [
          "expiresAt",
          "expireAt",
          "validUntil",
          "validTo",
        ]);

        graceMinutes = _readInt(decoded, [
          "graceMinutes",
          "lateMinutes",
          "allowedLateMinutes",
        ]) ??
            10;
      }
    } catch (_) {
      decoded = {};
    }

    if (decoded.isEmpty) {
      decoded = {
        "type": "legacy",
        "rawCode": code,
      };
    }

    return QRAttendancePayload(
      rawCode: code,
      type: type,
      courseId: courseId,
      courseTitle: courseTitle,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      sessionStartAt: sessionStartAt,
      expiresAt: expiresAt,
      graceMinutes: graceMinutes,
      rawData: decoded,
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final parsed = int.tryParse(value.toString().trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        final parsed = DateTime.tryParse(value.toString().trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}