import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';

class PaymentServiceGuard {
  static bool globalLock = false;
  static DateTime? lastSubmitTime;
  static String? lastUserId;
  static String? lastCourseId;
  static final Map<String, DateTime> _recentAttempts = {};

  static String _key({
    String? userId,
    String? courseId,
    String? plan,
  }) {
    return "${userId ?? ""}|${courseId ?? ""}|${plan ?? ""}";
  }

  static bool canSubmit({
    String? userId,
    String? courseId,
    String? plan,
  }) {
    final now = DateTime.now();
    final key = _key(userId: userId, courseId: courseId, plan: plan);

    if (globalLock) return false;

    _recentAttempts
        .removeWhere((_, time) => now.difference(time).inMinutes > 2);

    final recentKeyAttempt = _recentAttempts[key];
    if (recentKeyAttempt != null &&
        now.difference(recentKeyAttempt).inSeconds < 5) {
      return false;
    }

    if (lastSubmitTime != null &&
        now.difference(lastSubmitTime!).inMilliseconds < 2000) {
      return false;
    }

    if (lastUserId == userId && lastCourseId == courseId) {
      if (lastSubmitTime != null &&
          now.difference(lastSubmitTime!).inSeconds < 5) {
        return false;
      }
    }

    return true;
  }

  static void registerSubmit({
    String? userId,
    String? courseId,
    String? plan,
  }) {
    final now = DateTime.now();
    final key = _key(userId: userId, courseId: courseId, plan: plan);

    lastSubmitTime = now;
    lastUserId = userId;
    lastCourseId = courseId;
    _recentAttempts[key] = now;
  }

  static void reset() {
    globalLock = false;
    lastSubmitTime = null;
    lastUserId = null;
    lastCourseId = null;
    _recentAttempts.clear();
  }
}

Future<T?> safeExecute<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return null;
  }
}

class _PaymentSummary {
  final int totalPaid;
  final int remaining;
  final int approvedCount;
  final int pendingCount;
  final int rejectedCount;
  final int totalCount;
  final Map<String, dynamic>? latestPayment;
  final Map<String, dynamic>? latestApprovedPayment;

  const _PaymentSummary({
    required this.totalPaid,
    required this.remaining,
    required this.approvedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.totalCount,
    this.latestPayment,
    this.latestApprovedPayment,
  });
}

class PaymentService {
  static String? _lastUploadedPath;
  static bool _uploadingNow = false;
  static final Map<String, String> _courseTitleCache = {};

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return {};
  }

  static String _text(dynamic value) {
    return value == null ? "" : value.toString().trim();
  }

  static bool _bool(dynamic value) {
    return value == true;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(_text(value)) ?? 0;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_text(value)) ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _timeValue(Map<String, dynamic> data) {
    final candidates = [
      data['updatedAt'],
      data['approvedAt'],
      data['createdAt'],
      data['timestamp'],
      data['sessionDateTime'],
      data['date'],
    ];

    for (final item in candidates) {
      final dt = _date(item);
      if (dt != null) return dt.millisecondsSinceEpoch;
    }

    return 0;
  }

  static void _putIfNotEmpty(
    Map<String, dynamic> target,
    String key,
    dynamic value,
  ) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    target[key] = value;
  }

  static String _normalizeEmail(String text) {
    return text.trim().toLowerCase();
  }

  static String _normalizePhone(String text) {
    return text.replaceAll(RegExp(r'[^0-9+]'), '').trim();
  }

  static String _contentTypeFor({
    dynamic file,
    Uint8List? webImage,
  }) {
    final path = file == null ? "" : _text(file.path).toLowerCase();

    if (path.endsWith(".png")) return "image/png";
    if (path.endsWith(".gif")) return "image/gif";
    if (path.endsWith(".webp")) return "image/webp";
    if (path.endsWith(".jpg") || path.endsWith(".jpeg")) return "image/jpeg";

    final bytes = webImage;
    if (bytes != null && bytes.length >= 12) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return "image/png";
      }

      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return "image/jpeg";
      }

      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return "image/webp";
      }

      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return "image/gif";
      }
    }

    return "image/jpeg";
  }

  static Future<String> _resolveCourseTitle(String courseId) async {
    final id = _text(courseId);
    if (id.isEmpty) return "";

    if (_courseTitleCache.containsKey(id)) {
      return _courseTitleCache[id] ?? id;
    }

    try {
      final doc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(id)
          .get();

      final data = _safeMap(doc.data());
      final title = _text(data['title']).isNotEmpty
          ? _text(data['title'])
          : (_text(data['name']).isNotEmpty ? _text(data['name']) : id);

      _courseTitleCache[id] = title;
      return title;
    } catch (_) {
      return id;
    }
  }

  static String _resolveStudentId(Map<String, dynamic> userData) {
    final candidates = [
      _text(userData['studentId']),
      _text(userData['linkedStudentId']),
      _text(userData['linkedStudent']),
    ];

    for (final item in candidates) {
      if (item.isNotEmpty) return item;
    }

    return "";
  }

  static Future<List<Map<String, dynamic>>> _allUserPayments(
    String userId,
  ) async {
    final snap = await FirebaseService.firestore
        .collection(AppConstants.payments)
        .where('userId', isEqualTo: userId)
        .get();

    final items = snap.docs.map((doc) {
      final data = _safeMap(doc.data());
      data['_docId'] = doc.id;
      return data;
    }).toList();

    items.sort((a, b) => _timeValue(b).compareTo(_timeValue(a)));
    return items;
  }

  static _PaymentSummary _buildPaymentSummary(
    List<Map<String, dynamic>> payments,
  ) {
    final approved = payments
        .where((p) => _text(p['status']).toLowerCase() == 'approved')
        .toList();

    final pending = payments
        .where((p) => _text(p['status']).toLowerCase() == 'pending')
        .toList();

    final rejected = payments
        .where((p) => _text(p['status']).toLowerCase() == 'rejected')
        .toList();

    final totalPaid = approved.fold<int>(0, (total, payment) {
      return total + _int(payment['paid']);
    });

    final remaining = approved.fold<int>(0, (total, payment) {
      return total + _int(payment['remaining']);
    });

    final latestPayment = payments.isEmpty ? null : payments.first;
    final latestApprovedPayment = approved.isEmpty ? null : approved.first;

    return _PaymentSummary(
      totalPaid: totalPaid,
      remaining: remaining,
      approvedCount: approved.length,
      pendingCount: pending.length,
      rejectedCount: rejected.length,
      totalCount: payments.length,
      latestPayment: latestPayment,
      latestApprovedPayment: latestApprovedPayment,
    );
  }

  static Future<void> _syncLinkedState(
    String userId, {
    Map<String, dynamic>? userData,
    String? latestPaymentStatus,
    String? overrideSubscriptionEnd,
  }) async {
    try {
      final userRef =
          FirebaseService.firestore.collection(AppConstants.users).doc(userId);
      final freshUserData = userData ?? _safeMap((await userRef.get()).data());
      final studentId = _resolveStudentId(freshUserData);

      final payments = await _allUserPayments(userId);
      final summary = _buildPaymentSummary(payments);

      final latest = summary.latestPayment;
      final latestApproved = summary.latestApprovedPayment;

      final resolvedSubscriptionEnd = _text(overrideSubscriptionEnd).isNotEmpty
          ? _text(overrideSubscriptionEnd)
          : _text(latestApproved?['subscriptionEnd']).isNotEmpty
              ? _text(latestApproved?['subscriptionEnd'])
              : _text(freshUserData['subscriptionEnd']);

      final financialStatus = summary.totalPaid <= 0
          ? 'pending'
          : (summary.remaining <= 0 ? 'settled' : 'due');

      final userUpdates = <String, dynamic>{
        "totalPaid": summary.totalPaid,
        "remaining": summary.remaining,
        "approvedPaymentsCount": summary.approvedCount,
        "pendingPaymentsCount": summary.pendingCount,
        "rejectedPaymentsCount": summary.rejectedCount,
        "paymentsCount": summary.totalCount,
        "financialStatus": financialStatus,
        "latestPaymentStatus": _text(latestPaymentStatus).isNotEmpty
            ? latestPaymentStatus
            : _text(latest?['status']),
        "latestPaymentId": _text(latest?['_docId']),
        "latestPaymentAmount": _double(latest?['paid']),
        "latestPaymentCourseId": _text(latest?['courseId']),
        "latestPaymentCourseTitle": _text(latest?['courseTitle']),
        "latestApprovedPaymentId": _text(latestApproved?['_docId']),
        "latestApprovedPaymentAmount": _double(latestApproved?['paid']),
        "latestApprovedCourseId": _text(latestApproved?['courseId']),
        "latestApprovedCourseTitle": _text(latestApproved?['courseTitle']),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      _putIfNotEmpty(userUpdates, "subscriptionEnd", resolvedSubscriptionEnd);
      _putIfNotEmpty(userUpdates, "name", _text(freshUserData['name']));
      _putIfNotEmpty(userUpdates, "phone", _text(freshUserData['phone']));
      _putIfNotEmpty(userUpdates, "email", _text(freshUserData['email']));
      _putIfNotEmpty(userUpdates, "image", _text(freshUserData['image']));
      _putIfNotEmpty(userUpdates, "studentId", studentId);

      if (_bool(freshUserData['isAdmin'])) {
        userUpdates['isAdmin'] = true;
      }

      if (_bool(freshUserData['isVIP'])) {
        userUpdates['isVIP'] = true;
      }

      if (_bool(freshUserData['blocked'])) {
        userUpdates['blocked'] = true;
      }

      await userRef.set(userUpdates, SetOptions(merge: true));

      if (studentId.isNotEmpty) {
        final studentRef =
            FirebaseService.firestore.collection("students").doc(studentId);
        final studentUpdates = <String, dynamic>{
          "linkedUserId": userId,
          "name": _text(freshUserData['name']),
          "phone": _text(freshUserData['phone']),
          "image": _text(freshUserData['image']),
          "totalPaid": summary.totalPaid,
          "remaining": summary.remaining,
          "approvedPaymentsCount": summary.approvedCount,
          "pendingPaymentsCount": summary.pendingCount,
          "rejectedPaymentsCount": summary.rejectedCount,
          "paymentsCount": summary.totalCount,
          "financialStatus": financialStatus,
          "latestPaymentStatus": _text(latestPaymentStatus).isNotEmpty
              ? latestPaymentStatus
              : _text(latest?['status']),
          "latestPaymentId": _text(latest?['_docId']),
          "latestPaymentAmount": _double(latest?['paid']),
          "latestPaymentCourseId": _text(latest?['courseId']),
          "latestPaymentCourseTitle": _text(latest?['courseTitle']),
          "latestApprovedPaymentId": _text(latestApproved?['_docId']),
          "latestApprovedPaymentAmount": _double(latestApproved?['paid']),
          "latestApprovedCourseId": _text(latestApproved?['courseId']),
          "latestApprovedCourseTitle": _text(latestApproved?['courseTitle']),
          "updatedAt": FieldValue.serverTimestamp(),
        };

        _putIfNotEmpty(
          studentUpdates,
          "subscriptionEnd",
          resolvedSubscriptionEnd,
        );

        await studentRef.set(studentUpdates, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Sync Linked State Error: $e");
    }
  }

  static Future<void> refreshLinkedState(String userId) async {
    await _syncLinkedState(userId);
  }

  static Future<Map<String, dynamic>> getStudentDashboardData(
    String userId,
  ) async {
    final userDoc = await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(userId)
        .get();

    final userData = _safeMap(userDoc.data());
    final studentId = _resolveStudentId(userData);

    Map<String, dynamic> studentData = {};
    if (studentId.isNotEmpty) {
      final studentDoc = await FirebaseService.firestore
          .collection("students")
          .doc(studentId)
          .get();
      studentData = _safeMap(studentDoc.data());
    }

    final payments = await _allUserPayments(userId);
    final paymentSummary = _buildPaymentSummary(payments);

    final attendanceSnap = await FirebaseService.firestore
        .collectionGroup("records")
        .where("userId", isEqualTo: userId)
        .get();

    final attendanceDocs = attendanceSnap.docs.map((doc) {
      final data = _safeMap(doc.data());
      data['_docId'] = doc.id;
      return data;
    }).toList();

    attendanceDocs.sort((a, b) => _timeValue(b).compareTo(_timeValue(a)));

    final attendanceTotal = attendanceDocs.length;
    final attendancePresent =
        attendanceDocs.where((e) => _bool(e['present'])).length;
    final attendanceLate = attendanceDocs.where((e) => _bool(e['late'])).length;
    final attendanceAbsent = attendanceTotal - attendancePresent;
    final attendanceRate = attendanceTotal == 0
        ? 0.0
        : (attendancePresent / attendanceTotal) * 100;

    final enrolledCourses = _stringList(userData['enrolledCourses']);
    final courseTitles = <String, String>{};
    await Future.wait(enrolledCourses.map((courseId) async {
      courseTitles[courseId] = await _resolveCourseTitle(courseId);
    }));

    return {
      "user": userData,
      "student": studentData,
      "financial": {
        "totalPaid": paymentSummary.totalPaid,
        "remaining": paymentSummary.remaining,
        "approvedPaymentsCount": paymentSummary.approvedCount,
        "pendingPaymentsCount": paymentSummary.pendingCount,
        "rejectedPaymentsCount": paymentSummary.rejectedCount,
        "paymentsCount": paymentSummary.totalCount,
        "latestPayment": paymentSummary.latestPayment,
        "latestApprovedPayment": paymentSummary.latestApprovedPayment,
      },
      "attendance": {
        "total": attendanceTotal,
        "present": attendancePresent,
        "late": attendanceLate,
        "absent": attendanceAbsent,
        "rate": attendanceRate,
        "recent": attendanceDocs.take(5).toList(),
      },
      "courses": {
        "ids": enrolledCourses,
        "titles": courseTitles,
      },
      "recentPayments": payments.take(5).toList(),
    };
  }

  static Future<String?> uploadImage({
    dynamic file,
    Uint8List? webImage,
    bool isCourse = false,
    String? customFolder,
  }) async {
    if (_uploadingNow || PaymentServiceGuard.globalLock) return null;

    try {
      _uploadingNow = true;

      await FirebaseService.auth.currentUser?.reload();
      await FirebaseService.auth.currentUser?.getIdToken(true);

      final user = FirebaseService.auth.currentUser;
      debugPrint("USER => ${user?.uid}");
      if (user == null) return null;

      if (file == null && webImage == null) return null;

      if (file != null && !kIsWeb) {
        final sizeMB = (file.lengthSync() as int) / (1024 * 1024);
        if (sizeMB > AppConstants.maxUploadSizeMB) {
          debugPrint("❌ File too large");
          return null;
        }
      }

      if (webImage != null) {
        final sizeMB = webImage.lengthInBytes / (1024 * 1024);
        if (sizeMB > AppConstants.maxUploadSizeMB) {
          debugPrint("❌ Web image too large");
          return null;
        }
      }

      final userDoc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final userData = _safeMap(userDoc.data());

      if (userData['blocked'] == true) return null;

      final now = DateTime.now();
      final name = "${user.uid}_${now.microsecondsSinceEpoch}";

      if (_lastUploadedPath == name) return null;
      _lastUploadedPath = name;

      final folder = customFolder ??
          (isCourse ? "courses/images" : AppConstants.paymentFolder);
      final ref = FirebaseService.storage.ref().child("$folder/$name.jpg");

      final metadata = SettableMetadata(
        contentType: _contentTypeFor(file: file, webImage: webImage),
      );

      UploadTask task;

      if (webImage != null) {
        task = ref.putData(webImage, metadata);
      } else {
        task = ref.putFile(file as dynamic, metadata);
      }

      await task.timeout(const Duration(seconds: 30));

      final url = await ref.getDownloadURL();
      debugPrint("IMAGE URL => $url");

      if (url.isEmpty) return null;
      if (!url.startsWith("http")) return null;

      return url;
    } catch (e) {
      debugPrint("🔥 Upload Error: $e");
      return null;
    } finally {
      _uploadingNow = false;
    }
  }

  static DateTime? getEndDate(String plan) {
    if (plan == AppConstants.planMonthly) {
      return DateTime.now().add(const Duration(days: 30));
    }

    if (plan == AppConstants.planYearly) {
      return DateTime.now().add(const Duration(days: 365));
    }

    return null;
  }

  static bool validatePayment({
    required int price,
    required int paid,
    required int remaining,
    required String email,
    required String phone,
    required String plan,
    String? courseId,
    String? imageUrl,
  }) {
    if (price <= 0) return false;
    if (paid <= 0) return false;
    if (paid > price) return false;

    final calculatedRemaining = calculateRemaining(price: price, paid: paid);
    if (remaining != calculatedRemaining) return false;

    if (email.isEmpty) return false;
    if (!email.contains("@") || !email.contains(".")) return false;

    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return false;

    if (plan.trim().isEmpty) return false;

    if (plan == AppConstants.planSingleCourse &&
        (courseId == null || courseId.trim().isEmpty)) {
      return false;
    }

    if (imageUrl != null && imageUrl.trim().isEmpty) return false;

    return true;
  }

  static String clean(String text) {
    return text.trim();
  }

  static Future<bool> submitPayment({
    required String userId,
    required String email,
    required String phone,
    required String plan,
    required int price,
    required int paid,
    required int remaining,
    String? courseId,
    String? courseTitle,
    String? imageUrl,
    String? submittedByUserId,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedPhone = _normalizePhone(phone);
    final normalizedCourseId = _text(courseId);

    if (userId.isEmpty) return false;
    if (imageUrl == null || imageUrl.isEmpty) return false;

    if (!validatePayment(
      price: price,
      paid: paid,
      remaining: remaining,
      email: normalizedEmail,
      phone: normalizedPhone,
      plan: plan,
      courseId: normalizedCourseId,
      imageUrl: imageUrl,
    )) {
      debugPrint("❌ Invalid Payment Data");
      return false;
    }

    if (!PaymentServiceGuard.canSubmit(
      userId: userId,
      courseId: normalizedCourseId,
      plan: plan,
    )) {
      debugPrint("🚫 Blocked by Guard");
      return false;
    }

    PaymentServiceGuard.globalLock = true;

    try {
      final userDoc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .get();

      final userData = _safeMap(userDoc.data());

      if (userData['isAdmin'] == true) return false;
      if (userData['blocked'] == true) return false;

      final resolvedStudentId = _resolveStudentId(userData);
      final resolvedCourseTitle = normalizedCourseId.isNotEmpty
          ? (courseTitle != null && courseTitle.trim().isNotEmpty
              ? courseTitle.trim()
              : await _resolveCourseTitle(normalizedCourseId))
          : "";

      final paymentsRef =
          FirebaseService.firestore.collection(AppConstants.payments);

      final existingPayments = await _allUserPayments(userId);

      final samePlanPayments = existingPayments.where((payment) {
        return _text(payment['courseId']) == normalizedCourseId &&
            _text(payment['plan']) == plan;
      }).toList();

      final hasPendingSame = samePlanPayments.any((payment) {
        return _text(payment['status']).toLowerCase() == 'pending';
      });

      if (hasPendingSame) {
        debugPrint("⚠️ Duplicate Pending Payment");
        return false;
      }

      final hasApprovedFullSingleCourse = samePlanPayments.any((payment) {
        return _text(payment['status']).toLowerCase() == 'approved' &&
            _int(payment['remaining']) <= 0 &&
            plan == AppConstants.planSingleCourse &&
            normalizedCourseId.isNotEmpty;
      });

      if (hasApprovedFullSingleCourse) {
        debugPrint("⚠️ Already Paid");
        return false;
      }

      final endDate = getEndDate(plan);

      final data = {
        "userId": userId,
        "studentId": resolvedStudentId,
        "userName": _text(userData['name']),
        "email": normalizedEmail,
        "phone": normalizedPhone,
        "plan": plan,
        "courseId": normalizedCourseId,
        "courseTitle": resolvedCourseTitle,
        "price": price,
        "paid": paid,
        "remaining": remaining,
        "imageUrl": imageUrl,
        "receiptUrl": imageUrl,
        "status": "pending",
        "paymentType": remaining > 0 ? "partial" : "full",
        "submittedFrom": "student_profile",
        "submittedBy": submittedByUserId ?? "",
        "subscriptionEnd": endDate?.toIso8601String() ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final docRef = await paymentsRef.add(data);

      PaymentServiceGuard.registerSubmit(
        userId: userId,
        courseId: normalizedCourseId,
        plan: plan,
      );

      await _syncLinkedState(
        userId,
        userData: userData,
        latestPaymentStatus: "pending",
      );

      if (resolvedStudentId.isNotEmpty) {
        await FirebaseService.firestore
            .collection("students")
            .doc(resolvedStudentId)
            .set({
          "linkedUserId": userId,
          "lastPaymentRequestId": docRef.id,
          "lastPaymentRequestStatus": "pending",
          "lastPaymentRequestAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint("✅ Payment Submitted");
      return true;
    } catch (e) {
      debugPrint("🔥 Payment Error: $e");
      return false;
    } finally {
      PaymentServiceGuard.globalLock = false;
    }
  }

  static Future<void> approvePayment({
    required String paymentId,
    required Map<String, dynamic> data,
    String? approvedByUserId,
  }) async {
    try {
      final paymentsRef =
          FirebaseService.firestore.collection(AppConstants.payments);

      final paymentData = _safeMap(data);
      final userId = _text(paymentData['userId']);
      final plan = _text(paymentData['plan']);
      final courseId = _text(paymentData['courseId']);
      final courseTitle = _text(paymentData['courseTitle']);
      final remaining = _int(paymentData['remaining']);
      final studentId = _text(paymentData['studentId']);

      String? subscriptionEnd = _text(paymentData['subscriptionEnd']);
      if (subscriptionEnd.isEmpty &&
          (plan == AppConstants.planMonthly ||
              plan == AppConstants.planYearly)) {
        subscriptionEnd = getEndDate(plan)?.toIso8601String();
      }

      // ✅ تحديث payment نفسه
      await paymentsRef.doc(paymentId).set({
        "status": "approved",
        "approvedAt": FieldValue.serverTimestamp(),
        "approvedBy": approvedByUserId ?? "",
        "subscriptionEnd": subscriptionEnd ?? "",
        "courseTitle": courseTitle, // 🔥 استخدمناه هنا
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (userId.isEmpty) return;

      final userRef =
          FirebaseService.firestore.collection(AppConstants.users).doc(userId);

      // ✅ اشتراك عام
      if (plan == AppConstants.planMonthly || plan == AppConstants.planYearly) {
        await userRef.set({
          "subscribed": true,
          "subscriptionEnd": subscriptionEnd ?? "",
          "latestPaymentStatus": "approved",
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // ✅ كورس
      if (plan == AppConstants.planSingleCourse &&
          courseId.isNotEmpty &&
          remaining <= 0) {
        await userRef.set({
          "unlockedCourses": FieldValue.arrayUnion([courseId]),
          "enrolledCourses": FieldValue.arrayUnion([courseId]),
          "latestPaymentStatus": "approved",
          "lastCourseTitle": courseTitle, // 🔥 مهم للداشبورد
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ تحديث student (CRM)
        if (studentId.isNotEmpty) {
          await FirebaseService.firestore
              .collection("students")
              .doc(studentId)
              .set({
            "enrolledCourses": FieldValue.arrayUnion([courseId]),
            "lastCourseTitle": courseTitle, // 🔥 ربط CRM
            "updatedAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // ✅ مزامنة عامة
      await _syncLinkedState(
        userId,
        latestPaymentStatus: "approved",
        overrideSubscriptionEnd: subscriptionEnd,
      );

      debugPrint("✅ Payment Approved");
    } catch (e) {
      debugPrint("🔥 Approve Error: $e");
    }
  }

  static Future<void> rejectPayment(
    String paymentId, {
    String? reason,
  }) async {
    try {
      final paymentRef = FirebaseService.firestore
          .collection(AppConstants.payments)
          .doc(paymentId);

      final doc = await paymentRef.get();
      final data = _safeMap(doc.data());
      final userId = _text(data['userId']);

      await paymentRef.set({
        "status": "rejected",
        "rejectedAt": FieldValue.serverTimestamp(),
        "rejectedReason": reason ?? "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (userId.isNotEmpty) {
        await _syncLinkedState(
          userId,
          latestPaymentStatus: "rejected",
        );
      }

      debugPrint("❌ Payment Rejected");
    } catch (e) {
      debugPrint("🔥 Reject Error: $e");
    }
  }

  static int calculateRemaining({
    required int price,
    required int paid,
  }) {
    final remaining = price - paid;
    return remaining < 0 ? 0 : remaining;
  }

  static bool isFullyPaid({
    required int price,
    required int paid,
  }) {
    return paid >= price;
  }
}
