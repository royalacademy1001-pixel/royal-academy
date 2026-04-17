import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../core/permission_service.dart';

class StudentProfileController extends ChangeNotifier {
  final name = TextEditingController();
  final phone = TextEditingController();

  String email = "";
  String imageUrl = "";

  bool validSubscription = false;
  bool isAdmin = false;
  bool isVIP = false;
  bool blocked = false;

  bool instructorRequest = false;
  bool instructorApproved = false;

  String? subscriptionEnd;
  List<String> enrolledCourses = [];

  Uint8List? profileImageBytes;
  final picker = ImagePicker();

  bool loading = true;

  Map<String, String> courseNames = {};
  static final Map<String, String> _courseCache = {};

  StreamSubscription? _userSub;
  StreamSubscription? _studentSub;

  String? studentId;
  Map<String, dynamic>? studentData;

  String? _activeStudentId;

  String role = "normal";

  bool _disposed = false;

  String _text(dynamic value) {
    return value == null ? "" : value.toString();
  }

  bool _bool(dynamic value) {
    return value == true;
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(_text(value)) ?? 0;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_text(value)) ?? 0;
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String formatDate(dynamic value) {
    final date = _asDate(value);
    if (date == null) return "";
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$y-$m-$d";
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  void _notifySafe() {
    if (_disposed) return;
    notifyListeners();
  }

  int profileCompletion() {
    final checks = [
      name.text.trim().isNotEmpty,
      phone.text.trim().isNotEmpty,
      email.trim().isNotEmpty,
      imageUrl.isNotEmpty || profileImageBytes != null,
      studentId != null && studentId!.isNotEmpty,
      enrolledCourses.isNotEmpty,
      subscriptionEnd != null && subscriptionEnd!.trim().isNotEmpty,
    ];

    return ((checks.where((e) => e).length / checks.length) * 100).round();
  }

  ImageProvider? avatarProvider() {
    if (profileImageBytes != null) {
      return MemoryImage(profileImageBytes!);
    }
    if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  void _applyUserData(Map<String, dynamic> data) {
    final currentName = _text(data['name']);
    final currentPhone = _text(data['phone']);
    final currentEmail = _text(data['email']);

    if (name.text != currentName) {
      name.text = currentName;
    }

    if (phone.text != currentPhone) {
      phone.text = currentPhone;
    }

    email = currentEmail.isNotEmpty
        ? currentEmail
        : (FirebaseService.auth.currentUser?.email ?? "");

    imageUrl = _text(data['image']);

    enrolledCourses = _stringList(data['enrolledCourses']);
    isAdmin = _bool(data['isAdmin']);
    isVIP = _bool(data['isVIP']);
    blocked = _bool(data['blocked']);

    subscriptionEnd = _text(data['subscriptionEnd']).isEmpty
        ? null
        : _text(data['subscriptionEnd']);

    instructorRequest = _bool(data['instructorRequest']);
    instructorApproved = _bool(data['instructorApproved']);

    final sid = _text(data['studentId']);
    studentId = sid.isEmpty ? null : sid;

    final end = _asDate(subscriptionEnd);
    validSubscription = end != null && end.isAfter(DateTime.now());

    if (isAdmin || instructorApproved || isVIP) {
      validSubscription = true;
    }

    role = PermissionService.getRole(data);

    if (role.isEmpty) {
      if (isAdmin) {
        role = "admin";
      } else if (isVIP) {
        role = "vip";
      } else if (validSubscription) {
        role = "subscriber";
      } else {
        role = "normal";
      }
    }
  }

  Future<void> _listenStudentDoc(String sid) async {
    if (_disposed || sid.isEmpty) return;

    if (_activeStudentId == sid && _studentSub != null) {
      return;
    }

    await _studentSub?.cancel();
    _studentSub = null;
    _activeStudentId = sid;

    _studentSub = FirebaseService.firestore
        .collection("students")
        .doc(sid)
        .snapshots()
        .listen((doc) {
      if (_disposed) return;
      studentData = doc.data() ?? {};
      _notifySafe();
    });
  }

  Future<void> _ensureStudentRecord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (_disposed) return;

    final userName =
        _text(data['name']).isNotEmpty ? _text(data['name']) : name.text.trim();
    final userPhone =
        _text(data['phone']).isNotEmpty ? _text(data['phone']) : phone.text.trim();
    final userImage =
        _text(data['image']).isNotEmpty ? _text(data['image']) : imageUrl;

    String sid = _text(data['studentId']);

    if (sid.isEmpty) {
      final docRef = FirebaseService.firestore.collection("students").doc();
      sid = docRef.id;

      await docRef.set({
        "name": userName,
        "phone": userPhone,
        "linkedUserId": uid,
        "image": userImage,
        "totalPaid": 0,
        "remaining": 0,
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(uid)
          .set({
        "studentId": sid,
      }, SetOptions(merge: true));
    } else {
      final docRef = FirebaseService.firestore.collection("students").doc(sid);
      final existing = await docRef.get();

      if (_disposed) return;

      if (!existing.exists) {
        await docRef.set({
          "name": userName,
          "phone": userPhone,
          "linkedUserId": uid,
          "image": userImage,
          "totalPaid": 0,
          "remaining": 0,
          "status": "active",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          "name": userName,
          "phone": userPhone,
          "linkedUserId": uid,
          "image": userImage,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    if (_disposed) return;

    studentId = sid;
    await _listenStudentDoc(sid);
  }

  Future<void> loadCoursesNames() async {
    if (_disposed) return;

    final ids = enrolledCourses.where((e) => e.isNotEmpty).toList();

    courseNames.removeWhere((key, value) => !ids.contains(key));

    final futures = ids.map((id) async {
      if (_disposed) return;

      if (_courseCache.containsKey(id)) {
        courseNames[id] = _courseCache[id]!;
        return;
      }

      try {
        final doc = await FirebaseService.firestore
            .collection(AppConstants.courses)
            .doc(id)
            .get();

        if (_disposed) return;

        if (doc.exists) {
          final data = doc.data() ?? {};
          final title = _text(data['title']).isNotEmpty
              ? _text(data['title'])
              : "Course";

          courseNames[id] = title;
          _courseCache[id] = title;
        }
      } catch (_) {
        if (_disposed) return;
        courseNames[id] = id;
      }
    });

    await Future.wait(futures);
    _notifySafe();
  }

  Future<void> loadData() async {
    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      loading = false;
      _notifySafe();
      return;
    }

    loading = true;
    _notifySafe();

    try {
      await PermissionService.load();

      if (_disposed) return;

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      if (_disposed) return;

      final data = doc.data() ?? {};

      _applyUserData(data);

      await _ensureStudentRecord(user.uid, data);
      await loadCoursesNames();

      if (_disposed) return;

      loading = false;
      _notifySafe();

      await _userSub?.cancel();
      _userSub = FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        if (_disposed) return;
        final data = doc.data() ?? {};
        _applyUserData(data);
        await loadCoursesNames();
        _notifySafe();
      });
    } catch (_) {
      if (_disposed) return;
      loading = false;
      _notifySafe();
    }
  }

  Future<void> pickImage() async {
    if (_disposed) return;

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );

    if (_disposed) return;
    if (picked == null) return;

    profileImageBytes = await picked.readAsBytes();
    _notifySafe();
  }

  Future<String?> uploadImage(Uint8List bytes) async {
    if (_disposed) return imageUrl;

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseService.storage
          .ref()
          .child("${AppConstants.profileFolder}/$fileName.jpg");

      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (_) {
      return imageUrl;
    }
  }

  Future<void> saveData() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null || _disposed) return;

    loading = true;
    _notifySafe();

    try {
      String? url = imageUrl;

      if (profileImageBytes != null) {
        url = await uploadImage(profileImageBytes!);
      }

      if (_disposed) return;

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "name": name.text.trim(),
        "phone": phone.text.trim(),
        "image": url,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      imageUrl = url ?? imageUrl;
      profileImageBytes = null;

      await loadData();
    } catch (_) {}

    if (_disposed) return;

    loading = false;
    _notifySafe();
  }

  void disposeController() {
    _disposed = true;
    _userSub?.cancel();
    _studentSub?.cancel();
    name.dispose();
    phone.dispose();
  }
}