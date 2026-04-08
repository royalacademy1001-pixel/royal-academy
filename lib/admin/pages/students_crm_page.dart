import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';
import '../../utils/helpers.dart';

import 'student_results_full_page.dart';

class StudentsCRMPage extends StatefulWidget {
  const StudentsCRMPage({super.key});

  @override
  State<StudentsCRMPage> createState() => _StudentsCRMPageState();
}

class _StudentsCRMPageState extends State<StudentsCRMPage> {
  String search = "";
  String selectedFilter = "all";

  bool isAdmin = false;
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final data = await FirebaseService.getUserData(refresh: true);
      isAdmin = data['isAdmin'] == true;
    } catch (_) {}
    if (!mounted) return;
    setState(() => loadingUser = false);
  }

  String _text(dynamic value) => value == null ? "" : value.toString();

  bool _bool(dynamic value) => value == true;

  int _listLength(dynamic value) {
    if (value is List) return value.length;
    return 0;
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

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.white10,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "📊 CRM الطلاب",
            style: TextStyle(color: AppColors.gold),
          ),
          backgroundColor: AppColors.black,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              "❌ غير مسموح",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "📊 CRM الطلاب",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: () {
              if (!mounted) return;
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "🔍 ابحث بالاسم أو الإيميل أو الموبايل...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
              ),
              onChanged: (val) {
                setState(() => search = val);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _chip("الكل", selectedFilter == "all", () {
                  setState(() => selectedFilter = "all");
                }),
                const SizedBox(width: 8),
                _chip("VIP", selectedFilter == "vip", () {
                  setState(() => selectedFilter = "vip");
                }),
                const SizedBox(width: 8),
                _chip("Blocked", selectedFilter == "blocked", () {
                  setState(() => selectedFilter = "blocked");
                }),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.users)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "❌ خطأ في تحميل المستخدمين",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 لا يوجد طلاب",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                final filtered = users.where((u) {
                  final data = u.data() as Map<String, dynamic>? ?? {};
                  final name = _text(data['name']).toLowerCase();
                  final email = _text(data['email']).toLowerCase();
                  final phone = _text(data['phone']).toLowerCase();
                  final vip = _bool(data['isVIP']);
                  final blocked = _bool(data['blocked']);

                  final searchLower = search.trim().toLowerCase();
                  final searchMatch = searchLower.isEmpty ||
                      name.contains(searchLower) ||
                      email.contains(searchLower) ||
                      phone.contains(searchLower);

                  final filterMatch = selectedFilter == "all" ||
                      (selectedFilter == "vip" && vip) ||
                      (selectedFilter == "blocked" && blocked);

                  return searchMatch && filterMatch;
                }).toList();

                final totalStudents = users.length;
                final vipStudents = users.where((u) {
                  final data = u.data() as Map<String, dynamic>? ?? {};
                  return _bool(data['isVIP']);
                }).length;
                final blockedStudents = users.where((u) {
                  final data = u.data() as Map<String, dynamic>? ?? {};
                  return _bool(data['blocked']);
                }).length;

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 لا توجد نتائج",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () async {
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                    children: [
                      Row(
                        children: [
                          _metricCard(
                            "إجمالي الطلاب",
                            totalStudents.toString(),
                            Colors.blue,
                            Icons.group,
                          ),
                          _metricCard(
                            "VIP",
                            vipStudents.toString(),
                            Colors.green,
                            Icons.verified,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _metricCard(
                            "Blocked",
                            blockedStudents.toString(),
                            Colors.red,
                            Icons.block,
                          ),
                          _metricCard(
                            "النتائج",
                            filtered.length.toString(),
                            Colors.orange,
                            Icons.manage_search,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...filtered.map((u) {
                        final data = u.data() as Map<String, dynamic>? ?? {};

                        final courses = _listLength(data['enrolledCourses']);
                        final vip = _bool(data['isVIP']);
                        final blocked = _bool(data['blocked']);
                        final name = _text(data['name']).isEmpty
                            ? "Student"
                            : _text(data['name']);
                        final email = _text(data['email']);
                        final phone = _text(data['phone']);
                        final year = _text(data['year']);
                        final term = _text(data['term']);
                        final attendancePercent =
                            (data['attendancePercent'] is num)
                                ? (data['attendancePercent'] as num).toDouble()
                                : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email.isNotEmpty
                                              ? email
                                              : "لا يوجد إيميل",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            phone,
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
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _badge("📚 $courses", Colors.blue),
                                  if (vip) _badge("VIP", Colors.green),
                                  if (blocked) _badge("BLOCK", Colors.red),
                                  if (year.isNotEmpty)
                                    _badge(year, Colors.purple),
                                  if (term.isNotEmpty)
                                    _badge(term, Colors.orange),
                                  if (attendancePercent != null)
                                    _badge(
                                      "حضور ${attendancePercent.toStringAsFixed(1)}%",
                                      attendancePercent >= 75
                                          ? Colors.green
                                          : attendancePercent >= 50
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _actionButton("الحضور", Colors.orange, () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentAttendancePage(userId: u.id),
                                      ),
                                    );
                                  }),
                                  _actionButton("النتائج", Colors.green, () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentResultsFullPage(
                                            userId: u.id),
                                      ),
                                    );
                                  }),
                                  _actionButton("فلوس", Colors.amber, () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentFinancePage(userId: u.id),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentAttendancePage extends StatelessWidget {
  final String userId;

  const StudentAttendancePage({super.key, required this.userId});

  String _text(dynamic value) => value == null ? "" : value.toString();

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "📅 الحضور",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collectionGroup("records")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "خطأ في التحميل",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا يوجد حضور",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.docs.toList();

          data.sort((a, b) {
            final ad = a.data() as Map<String, dynamic>? ?? {};
            final bd = b.data() as Map<String, dynamic>? ?? {};

            final at = ad['sessionDateTime'] ?? ad['createdAt'];
            final bt = bd['sessionDateTime'] ?? bd['createdAt'];

            final aDate = at is Timestamp ? at.millisecondsSinceEpoch : 0;
            final bDate = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;

            return bDate.compareTo(aDate);
          });

          final total = data.length;
          final present = data
              .where((e) =>
                  ((e.data() as Map<String, dynamic>? ?? {})['present'] ??
                      false) ==
                  true)
              .length;
          final lateCount = data
              .where((e) =>
                  ((e.data() as Map<String, dynamic>? ?? {})['late'] ??
                      false) ==
                  true)
              .length;
          final percent = total == 0 ? 0.0 : (present / total) * 100;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ملخص الحضور",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge("الإجمالي: $total", Colors.blue),
                        _badge("حاضر: $present", Colors.green),
                        _badge("متأخر: $lateCount", Colors.orange),
                        _badge(
                          "النسبة: ${percent.toStringAsFixed(1)}%",
                          percent >= 75
                              ? Colors.green
                              : percent >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...data.map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                final subjectName = _text(d['subjectName']).isNotEmpty
                    ? _text(d['subjectName'])
                    : _text(d['sessionName']);
                final sessionDate =
                    formatDate(d['sessionDateTime'] ?? d['createdAt']);
                final sessionDateText = sessionDate.isNotEmpty
                    ? sessionDate
                    : _text(d['sessionDate']);
                final sessionTime = _text(d['sessionTime']);
                final presentValue = d['present'] == true;
                final lateValue = d['late'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        presentValue
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: presentValue ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName.isNotEmpty ? subjectName : "حصة",
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
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _badge(
                                  presentValue ? "حاضر" : "غائب",
                                  presentValue ? Colors.green : Colors.red,
                                ),
                                if (lateValue) _badge("متأخر", Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class StudentFinancePage extends StatelessWidget {
  final String userId;

  const StudentFinancePage({super.key, required this.userId});

  String _text(dynamic value) => value == null ? "" : value.toString();

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "💰 الحسابات",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("financial")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "خطأ في التحميل",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا توجد مدفوعات",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.docs.toList();

          data.sort((a, b) {
            final ad = a.data() as Map<String, dynamic>? ?? {};
            final bd = b.data() as Map<String, dynamic>? ?? {};

            final at = ad['timestamp'] ?? ad['createdAt'];
            final bt = bd['timestamp'] ?? bd['createdAt'];

            final aDate = at is Timestamp ? at.millisecondsSinceEpoch : 0;
            final bDate = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;

            return bDate.compareTo(aDate);
          });

          final totalPaid = data.fold<double>(0, (total, doc) {
            final d = doc.data() as Map<String, dynamic>? ?? {};
            return total + amount(d['amount']);
          });

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ملخص الحسابات",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge("عدد العمليات: ${data.length}", Colors.blue),
                        _badge(
                          "إجمالي المدفوع: ${totalPaid.toStringAsFixed(0)}",
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...data.map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                final amountValue = amount(d['amount']);
                final dateText = formatDate(d['timestamp'] ?? d['createdAt']);
                final note = _text(d['note']).isNotEmpty
                    ? _text(d['note'])
                    : _text(d['description']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments,
                        color: amountValue >= 0 ? Colors.green : Colors.red,
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
              }),
            ],
          );
        },
      ),
    );
  }
}
