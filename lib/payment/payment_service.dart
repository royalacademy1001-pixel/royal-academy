// 🔥 IMPORTS FIRST
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';


// 🔥🔥🔥 ULTRA PAYMENT SERVICE UPGRADE LAYER 🔥🔥🔥

class PaymentServiceGuard {
  static bool globalLock = false;
  static DateTime? lastSubmitTime;
  static String? lastUserId;
  static String? lastCourseId;

  static bool canSubmit({
    String? userId,
    String? courseId,
  }) {
    final now = DateTime.now();

    if (globalLock) return false;

    if (lastSubmitTime != null) {
      if (now.difference(lastSubmitTime!).inMilliseconds < 2000) {
        return false;
      }
    }

    if (lastUserId == userId && lastCourseId == courseId) {
      if (lastSubmitTime != null &&
          now.difference(lastSubmitTime!).inSeconds < 5) {
        return false;
      }
    }

    lastSubmitTime = now;
    lastUserId = userId;
    lastCourseId = courseId;

    return true;
  }
}

Future<T?> safeExecute<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return null;
  }
}

// 🔥🔥🔥 END UPGRADE LAYER 🔥🔥🔥


// 🔥 FINAL PAYMENT SERVICE

class PaymentService {

  static String? _lastUploadedPath;
  static bool _uploadingNow = false;

  static Future<String?> uploadImage({
    File? file,
    Uint8List? webImage,
    bool isCourse = false,
  }) async {

    if (_uploadingNow || PaymentServiceGuard.globalLock) return null;

    try {
      _uploadingNow = true;

      await FirebaseService.auth.currentUser?.reload();
      await FirebaseService.auth.currentUser?.getIdToken(true);

      var user = FirebaseService.auth.currentUser;
      debugPrint("USER => ${user?.uid}");
      if (user == null) return null;

      final userDoc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      if (userData['isAdmin'] == true) return null;

      if (file == null && webImage == null) return null;

      if (file != null) {
        final sizeMB = file.lengthSync() / (1024 * 1024);
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

      final now = DateTime.now();
      final name = "${user.uid}_${now.microsecondsSinceEpoch}";

      if (_lastUploadedPath == name) return null;
      _lastUploadedPath = name;

      final folder = isCourse ? "courses/images" : AppConstants.paymentFolder;

      final ref = FirebaseService.storage
          .ref()
          .child("$folder/$name.jpg");

      final metadata = SettableMetadata(contentType: "image/jpeg");

      UploadTask task;

      if (webImage != null) {
        task = ref.putData(webImage, metadata);
      } else {
        task = ref.putFile(file!, metadata);
      }

      await task.timeout(const Duration(seconds: 30));

      final url = await ref.getDownloadURL();
      print("IMAGE URL => $url");

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

  static DateTime getEndDate(String plan) {
    if (plan == AppConstants.planMonthly) {
      return DateTime.now().add(const Duration(days: 30));
    }

    if (plan == AppConstants.planYearly) {
      return DateTime.now().add(const Duration(days: 365));
    }

    return DateTime.now();
  }

  static bool validatePayment({
    required int price,
    required int paid,
    required String email,
    required String phone,
  }) {

    if (price <= 0) return false;
    if (paid <= 0) return false;
    if (paid > price) return false;

    if (!email.contains("@") || !email.contains(".")) return false;

    if (phone.length < 10) return false;

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
    String? imageUrl,
  }) async {

    if (!PaymentServiceGuard.canSubmit(
      userId: userId,
      courseId: courseId,
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

      final userData = userDoc.data() ?? {};

      if (userData['isAdmin'] == true) return false;

      email = clean(email);
      phone = clean(phone);

      if (userId.isEmpty) return false;

      if (imageUrl == null || imageUrl.isEmpty) return false;

      if (!validatePayment(
        price: price,
        paid: paid,
        email: email,
        phone: phone,
      )) {
        debugPrint("❌ Invalid Payment Data");
        return false;
      }

      final paymentsRef =
          FirebaseService.firestore.collection(AppConstants.payments);

      final recent = await paymentsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (recent.docs.isNotEmpty) {
        final lastTime = recent.docs.first.data()['createdAt'];

        if (lastTime is Timestamp) {
          final diff =
              DateTime.now().difference(lastTime.toDate()).inSeconds;

          if (diff < 10) {
            debugPrint("⚠️ Spam Blocked");
            return false;
          }
        }
      }

      final existing = await paymentsRef
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: "pending")
          .get();

      for (var doc in existing.docs) {
        final d = doc.data();

        if ((d['courseId'] ?? "") == (courseId ?? "") &&
            (d['plan'] ?? "") == plan) {
          debugPrint("⚠️ Duplicate Payment");
          return false;
        }
      }

      int finalPaid = paid;

      if (courseId != null && courseId.isNotEmpty) {
        final oldPayments = await paymentsRef
            .where('userId', isEqualTo: userId)
            .where('courseId', isEqualTo: courseId)
            .where('status', isEqualTo: "approved")
            .get();

        for (var doc in oldPayments.docs) {
          final d = doc.data();

          final oldPaid =
              int.tryParse(d['paid']?.toString() ?? "0") ?? 0;

          final oldRemaining =
              int.tryParse(d['remaining']?.toString() ?? "0") ?? 0;

          final coursePrice =
              int.tryParse(d['price']?.toString() ?? "0") ?? 0;

          if (oldRemaining <= 0 && coursePrice > 0) {
            finalPaid = coursePrice;
          } else {
            finalPaid += oldPaid;
          }
        }
      }

      if (finalPaid > price) {
        finalPaid = price;
      }

      final finalRemaining =
          calculateRemaining(price: price, paid: finalPaid);

      final endDate = getEndDate(plan);

      final data = {
        "userId": userId,
        "email": email,
        "phone": phone,
        "plan": plan,
        "courseId": courseId ?? "",
        "price": price,
        "paid": finalPaid,
        "remaining": finalRemaining,
        "imageUrl": imageUrl ?? "",
        "status": "pending",
        "paymentType": finalPaid < price ? "partial" : "full",
        "subscriptionEnd": endDate.toIso8601String(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await paymentsRef.add(data);

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
  }) async {
    try {

      final paymentsRef =
          FirebaseService.firestore.collection(AppConstants.payments);

      await paymentsRef.doc(paymentId).update({
        "status": "approved",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      final userId = data['userId'] ?? "";
      final plan = data['plan'] ?? "";
      final courseId = data['courseId'];
      final remaining = int.tryParse(data['remaining']?.toString() ?? "0") ?? 0;

      if (userId.isEmpty) return;

      final userRef = FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId);

      if (plan == AppConstants.planMonthly ||
          plan == AppConstants.planYearly) {

        await userRef.set({
          "subscribed": true,
          "subscriptionEnd": data['subscriptionEnd'],
        }, SetOptions(merge: true));
      }

      if (plan == AppConstants.planSingleCourse &&
          courseId != null &&
          courseId.toString().isNotEmpty &&
          remaining <= 0) {

        await userRef.set({
          "unlockedCourses":
              FieldValue.arrayUnion([courseId]),
          "enrolledCourses":
              FieldValue.arrayUnion([courseId])
        }, SetOptions(merge: true));
      }

      debugPrint("✅ Payment Approved");

    } catch (e) {
      debugPrint("🔥 Approve Error: $e");
    }
  }

  static Future<void> rejectPayment(String paymentId) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.payments)
          .doc(paymentId)
          .update({
        "status": "rejected",
        "updatedAt": FieldValue.serverTimestamp(),
      });

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