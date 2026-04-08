import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_widget.dart';

import '../user_payments_page.dart';
import '../course_details_page.dart';
import '../payment/payment_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _studentSub?.cancel();
    name.dispose();
    phone.dispose();
    super.dispose();
  }

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

  String _formatDate(dynamic value) {
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

  int _profileCompletion() {
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

  ImageProvider? _avatarProvider() {
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
  }

  Future<void> _listenStudentDoc(String sid) async {
    if (sid.isEmpty) return;

    if (_activeStudentId == sid && _studentSub != null) {
      return;
    }

    _studentSub?.cancel();
    _activeStudentId = sid;

    _studentSub = FirebaseService.firestore
        .collection("students")
        .doc(sid)
        .snapshots()
        .listen(
      (doc) {
        studentData = doc.data() ?? {};
        if (!mounted) return;
        setState(() {});
      },
      onError: (e) {
        debugPrint("Student Stream Error: $e");
      },
    );
  }

  Future<void> _ensureStudentRecord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final userName = _text(data['name']).isNotEmpty ? _text(data['name']) : name.text.trim();
    final userPhone = _text(data['phone']).isNotEmpty ? _text(data['phone']) : phone.text.trim();
    final userImage = _text(data['image']).isNotEmpty ? _text(data['image']) : imageUrl;

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

    studentId = sid;
    await _listenStudentDoc(sid);
  }

  Future<void> loadCoursesNames() async {
    final ids = enrolledCourses.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    if (ids.isEmpty) {
      courseNames.clear();
      if (mounted) setState(() {});
      return;
    }

    courseNames.removeWhere((key, value) => !ids.contains(key));

    final futures = ids.map((id) async {
      if (_courseCache.containsKey(id)) {
        courseNames[id] = _courseCache[id]!;
        return;
      }

      try {
        final doc = await FirebaseService.firestore
            .collection(AppConstants.courses)
            .doc(id)
            .get();

        if (doc.exists) {
          final data = doc.data() ?? {};
          final title = _text(data['title']).isNotEmpty
              ? _text(data['title'])
              : (_text(data['name']).isNotEmpty ? _text(data['name']) : "Course");

          courseNames[id] = title;
          _courseCache[id] = title;
        } else {
          courseNames[id] = id;
        }
      } catch (_) {
        courseNames[id] = id;
      }
    });

    await Future.wait(futures);

    if (mounted) setState(() {});
  }

  Future<void> _handleUserSnapshot(Map<String, dynamic> data, String uid) async {
    _applyUserData(data);
    await _ensureStudentRecord(uid, data);
    await loadCoursesNames();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _reloadData() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(user.uid)
        .get();

    final data = userDoc.data() ?? {};
    await _handleUserSnapshot(data, user.uid);
  }

  Future<void> loadData() async {
    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => loading = false);
      }
      return;
    }

    try {
      await _reloadData();

      if (mounted) {
        setState(() => loading = false);
      }

      _userSub?.cancel();
      _userSub = FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .snapshots()
          .listen(
        (doc) async {
          final data = doc.data() ?? {};
          await _handleUserSnapshot(data, user.uid);
        },
        onError: (e) {
          debugPrint("User Stream Error: $e");
        },
      );
    } catch (e) {
      debugPrint("Profile Load Error: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (!mounted) return;

      setState(() {
        profileImageBytes = bytes;
      });
    } catch (e) {
      debugPrint("Pick Image Error: $e");
      showSnack("❌ تعذر اختيار الصورة", color: Colors.red);
    }
  }

  Future<String?> uploadImage(Uint8List bytes) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseService.storage
          .ref()
          .child("${AppConstants.profileFolder}/$fileName.jpg");

      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Image Error: $e");
      return imageUrl;
    }
  }

  Future<void> saveData() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      String? url = imageUrl;

      if (profileImageBytes != null) {
        url = await uploadImage(profileImageBytes!);
      }

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "name": name.text.trim(),
        "phone": phone.text.trim(),
        "image": url,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (studentId != null && studentId!.isNotEmpty) {
        await FirebaseService.firestore
            .collection("students")
            .doc(studentId)
            .set({
          "name": name.text.trim(),
          "phone": phone.text.trim(),
          "image": url,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      imageUrl = url ?? imageUrl;
      profileImageBytes = null;

      await _reloadData();

      showSnack("تم الحفظ ✅");
    } catch (e) {
      debugPrint("Save Error: $e");
      showSnack("❌ خطأ", color: Colors.red);
    }

    if (mounted) {
      setState(() => loading = false);
    }
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

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeroCard(ImageProvider? imageProvider) {
    final completion = _profileCompletion();
    final daysLeft = _asDate(subscriptionEnd)?.difference(DateTime.now()).inDays;

    return _panel(
      child: Column(
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.gold,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.camera_alt, color: Colors.black)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name.text.isEmpty ? "اسم المستخدم" : name.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email.isEmpty ? "لا يوجد إيميل" : email,
            style: const TextStyle(color: Colors.grey),
          ),
          if (phone.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone.text,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          if (studentId != null && studentId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statusChip("Student ID: $studentId", Colors.blue),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80
                    ? Colors.green
                    : completion >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "اكتمال الملف: $completion%",
            style: TextStyle(
              color: completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _statusChip(
                validSubscription ? "اشتراك نشط" : "اشتراك غير نشط",
                validSubscription ? Colors.green : Colors.red,
              ),
              if (isAdmin) _statusChip("Admin", Colors.orange),
              if (isVIP) _statusChip("VIP", Colors.green),
              if (instructorApproved) _statusChip("Instructor", Colors.blue),
              if (instructorRequest) _statusChip("طلب مدرس", Colors.amber),
              if (blocked) _statusChip("Blocked", Colors.red),
              if (daysLeft != null)
                _statusChip(
                  daysLeft >= 0 ? "باقي $daysLeft يوم" : "منتهي",
                  daysLeft >= 0 ? Colors.teal : Colors.red,
                ),
            ],
          ),
          if (subscriptionEnd != null) ...[
            const SizedBox(height: 12),
            Text(
              "ينتهي الاشتراك: ${_formatDate(subscriptionEnd)}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalPaid = _int(studentData?['totalPaid']);
    final remaining = _int(studentData?['remaining']);
    final completion = _profileCompletion();

    return Column(
      children: [
        Row(
          children: [
            _metricCard(
              "الكورسات",
              enrolledCourses.length.toString(),
              Colors.blue,
              Icons.menu_book,
            ),
            _metricCard(
              "المدفوع",
              "$totalPaid",
              Colors.green,
              Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _metricCard(
              "المتبقي",
              "$remaining",
              remaining > 0 ? Colors.red : Colors.green,
              Icons.request_quote_outlined,
            ),
            _metricCard(
              "اكتمال الملف",
              "$completion%",
              completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              Icons.fact_check_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountStatusCard() {
    final statusText = _text(studentData?['status']).isNotEmpty
        ? _text(studentData?['status'])
        : "active";

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "حالة حسابك",
            subtitle: "كل المعلومات المهمة عن اشتراكك وربط الحساب",
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statusChip(
                "الحالة: $statusText",
                statusText.toLowerCase() == "active"
                    ? Colors.green
                    : Colors.orange,
              ),
              _statusChip(
                "الحضور: ${_calculateAttendanceHint()}",
                _attendanceHintColor(),
              ),
              _statusChip(
                "الاشتراك: ${validSubscription ? 'نشط' : 'منتهي'}",
                validSubscription ? Colors.green : Colors.red,
              ),
              if (studentData != null)
                _statusChip(
                  "مدفوعات الطلاب: ${_int(studentData?['totalPaid'])}",
                  Colors.blue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _attendanceHintColor() {
    final percent = _attendancePreviewPercent();
    if (percent >= 75) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  double _attendancePreviewPercent() {
    return _attendanceCachePercent;
  }

  double get _attendanceCachePercent {
    return 0;
  }

  String _calculateAttendanceHint() {
    return "راجع القسم أدناه";
  }

  Widget _buildAttendanceSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collectionGroup("records")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _panel(child: LoadingWidget());
        }

        if (snapshot.hasError) {
          return _panel(
            child: const Text(
              "❌ خطأ في تحميل الحضور",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = List<QueryDocumentSnapshot<Object?>>.from(
          snapshot.data?.docs ?? [],
        );

        docs.sort((a, b) {
          final ad = a.data() as Map<String, dynamic>? ?? {};
          final bd = b.data() as Map<String, dynamic>? ?? {};

          final at = ad['sessionDateTime'] ?? ad['createdAt'];
          final bt = bd['sessionDateTime'] ?? bd['createdAt'];

          final am = at is Timestamp ? at.millisecondsSinceEpoch : 0;
          final bm = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;

          return bm.compareTo(am);
        });

        final total = docs.length;
        final present = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return _bool(data['present']);
        }).length;

        final lateCount = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return _bool(data['late']);
        }).length;

        final absent = total - present;
        final rate = total == 0 ? 0.0 : (present / total) * 100;

        return _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                "الحضور",
                subtitle: "ملخص حضورك في كل الجلسات",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricCard(
                    "الإجمالي",
                    total.toString(),
                    Colors.blue,
                    Icons.event_note,
                  ),
                  _metricCard(
                    "حاضر",
                    present.toString(),
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metricCard(
                    "غائب",
                    absent.toString(),
                    Colors.red,
                    Icons.cancel_outlined,
                  ),
                  _metricCard(
                    "متأخر",
                    lateCount.toString(),
                    Colors.orange,
                    Icons.access_time,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate >= 75
                        ? Colors.green
                        : rate >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "نسبة الحضور: ${rate.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: rate >= 75
                      ? Colors.green
                      : rate >= 50
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              if (docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    "لا يوجد حضور مسجل حتى الآن",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  children: docs.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final subjectName = _text(data['subjectName']).isNotEmpty
                        ? _text(data['subjectName'])
                        : _text(data['sessionName']);
                    final sessionDateText = _text(data['sessionDate']).isNotEmpty
                        ? _text(data['sessionDate'])
                        : _formatDate(data['sessionDateTime'] ?? data['createdAt']);
                    final sessionTime = _text(data['sessionTime']);
                    final presentValue = _bool(data['present']);
                    final lateValue = _bool(data['late']);
                    final statusText = presentValue
                        ? (lateValue ? "متأخر" : "حاضر")
                        : "غائب";
                    final statusColor = presentValue
                        ? (lateValue ? Colors.orange : Colors.green)
                        : Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            presentValue
                                ? (lateValue
                                    ? Icons.access_time
                                    : Icons.check_circle)
                                : Icons.cancel_outlined,
                            color: statusColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subjectName.isNotEmpty ? subjectName : "جلسة حضور",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (sessionDateText.isNotEmpty) sessionDateText,
                                    if (sessionTime.isNotEmpty) sessionTime,
                                  ].join(" • "),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _statusChip(statusText, statusColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection("financial")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _panel(child: LoadingWidget());
        }

        if (snapshot.hasError) {
          return _panel(
            child: const Text(
              "❌ خطأ في تحميل الحسابات",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = List<QueryDocumentSnapshot<Object?>>.from(
          snapshot.data?.docs ?? [],
        );

        docs.sort((a, b) {
          final ad = a.data() as Map<String, dynamic>? ?? {};
          final bd = b.data() as Map<String, dynamic>? ?? {};

          final at = ad['timestamp'] ?? ad['createdAt'];
          final bt = bd['timestamp'] ?? bd['createdAt'];

          final am = at is Timestamp ? at.millisecondsSinceEpoch : 0;
          final bm = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;

          return bm.compareTo(am);
        });

        final totalPaidFromRecords = docs.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return sum + _double(data['amount']);
        });

        final latestAmount = docs.isNotEmpty
            ? _double((docs.first.data() as Map<String, dynamic>? ?? {})['amount'])
            : 0;

        final latestDate = docs.isNotEmpty
            ? _formatDate(
                (docs.first.data() as Map<String, dynamic>? ?? {})['timestamp'] ??
                    (docs.first.data() as Map<String, dynamic>? ?? {})['createdAt'],
              )
            : "";

        final remaining = _int(studentData?['remaining']);

        return _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                "الحسابات",
                subtitle: "كل المدفوعات والحالة المالية",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricCard(
                    "العمليات",
                    docs.length.toString(),
                    Colors.blue,
                    Icons.receipt_long,
                  ),
                  _metricCard(
                    "إجمالي المدفوع",
                    totalPaidFromRecords.toStringAsFixed(0),
                    Colors.green,
                    Icons.payments,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metricCard(
                    "آخر دفعة",
                    latestAmount.toStringAsFixed(0),
                    Colors.orange,
                    Icons.history,
                  ),
                  _metricCard(
                    "المتبقي",
                    remaining.toString(),
                    remaining > 0 ? Colors.red : Colors.green,
                    Icons.request_quote_outlined,
                  ),
                ],
              ),
              if (latestDate.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "آخر حركة: $latestDate",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              if (docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    "لا توجد مدفوعات مسجلة حتى الآن",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  children: docs.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final amountValue = _double(data['amount']);
                    final dateText = _formatDate(
                      data['timestamp'] ?? data['createdAt'],
                    );
                    final note = _text(data['note']).isNotEmpty
                        ? _text(data['note'])
                        : _text(data['description']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "مدفوع: ${amountValue.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dateText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    note,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursesSection() {
    if (enrolledCourses.isEmpty) {
      return _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              "كورساتي",
              subtitle: "لا توجد كورسات مسجلة على الحساب",
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.gold,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "لم يتم تسجيل أي كورس بعد",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: "💳 فتح الدفع والاشتراك",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final items = enrolledCourses.toList();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "كورساتي",
            subtitle: "اضغط على أي كورس لعرض التفاصيل",
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final id = items[index];
              final title = courseNames[id] ?? id;
              final palette = [
                Colors.blue,
                Colors.purple,
                Colors.green,
                Colors.orange,
                Colors.teal,
                Colors.red,
              ];
              final color = palette[index % palette.length];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailsPage(
                        title: title,
                        courseId: id,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "بيانات الحساب",
            subtitle: "عدّل اسمك ورقمك والصورة الشخصية",
          ),
          const SizedBox(height: 14),
          CustomTextField(hint: "الاسم", controller: name),
          const SizedBox(height: 10),
          CustomTextField(hint: "رقم الهاتف", controller: phone),
          const SizedBox(height: 14),
          CustomButton(
            text: "💾 حفظ التغييرات",
            onPressed: saveData,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "💰 مدفوعاتي",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserPaymentsPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "💳 تجديد الاشتراك",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "إجراءات سريعة",
            subtitle: "كل ما تحتاجه من مكان واحد",
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "🔄 تحديث اللوحة",
                  onPressed: () async {
                    await _reloadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "🚪 تسجيل الخروج",
                  onPressed: () async {
                    setState(() => loading = true);

                    await FirebaseService.auth.signOut();

                    if (!mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountLiveSummary() {
    final completion = _profileCompletion();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "ملخصك الشخصي",
            subtitle: "نظرة سريعة على حالتك الحالية",
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80
                    ? Colors.green
                    : completion >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "اكتمال الملف: $completion%",
            style: TextStyle(
              color: completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statusChip(
                validSubscription ? "اشتراك نشط" : "اشتراك غير نشط",
                validSubscription ? Colors.green : Colors.red,
              ),
              if (studentId != null && studentId!.isNotEmpty)
                _statusChip("مربوط", Colors.blue),
              if (isAdmin) _statusChip("Admin", Colors.orange),
              if (isVIP) _statusChip("VIP", Colors.green),
              if (instructorApproved) _statusChip("Instructor", Colors.indigo),
              if (instructorRequest) _statusChip("طلب مدرس", Colors.amber),
              if (blocked) _statusChip("Blocked", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentUser = FirebaseService.auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "👤 لوحة تحكم الطالب",
            style: TextStyle(color: AppColors.gold),
          ),
          backgroundColor: AppColors.black,
        ),
        body: const Center(
          child: Text(
            "يرجى تسجيل الدخول أولاً",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final imageProvider = _avatarProvider();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "👤 لوحة تحكم الطالب",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: () async {
              await _reloadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              setState(() => loading = true);

              await FirebaseService.auth.signOut();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _reloadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  _buildHeroCard(imageProvider),
                  const SizedBox(height: 16),
                  _buildAccountLiveSummary(),
                  const SizedBox(height: 16),
                  _buildOverviewCards(),
                  const SizedBox(height: 16),
                  _buildAccountStatusCard(),
                  const SizedBox(height: 16),
                  _buildAttendanceSection(currentUser.uid),
                  const SizedBox(height: 16),
                  _buildFinanceSection(currentUser.uid),
                  const SizedBox(height: 16),
                  _buildCoursesSection(),
                  const SizedBox(height: 16),
                  _buildEditSection(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black54,
              child: LoadingWidget(),
            ),
        ],
      ),
    );
  }
}