// 🔥 STUDENT FINANCIAL SYSTEM (CRM)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

import '/shared/widgets/loading_widget.dart';

class StudentFinancialPage extends StatefulWidget {
  const StudentFinancialPage({super.key});

  @override
  State<StudentFinancialPage> createState() => _StudentFinancialPageState();
}

class _StudentFinancialPageState extends State<StudentFinancialPage> {
  String search = "";
  String selectedUserId = "";
  List<QueryDocumentSnapshot> users = [];
  Map<String, String> userNames = {};

  int totalFees = 9000;
  int totalTerms = 4;

  bool loadingConfig = true;
  bool savingConfig = false;
  bool loadingUser = true;

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Map<String, dynamic> safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  int safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String safeString(dynamic v) {
    if (v == null) return "";
    return v.toString();
  }

  bool _bool(dynamic value) => value == true;

  int _listLength(dynamic value) {
    if (value is List) return value.length;
    return 0;
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

  int get termPrice {
    if (totalTerms <= 0) return 0;
    return (totalFees / totalTerms).round();
  }

  int getTermFromAmount(int amount) {
    if (termPrice <= 0) return 0;
    final terms = (amount / termPrice).floor();
    if (terms < 0) return 0;
    if (terms > totalTerms) return totalTerms;
    return terms;
  }

  int getRemainingAmount(int amount) {
    final remaining = totalFees - amount;
    return remaining < 0 ? 0 : remaining;
  }

  int getRemainingTerms(int amount) {
    final remaining = totalTerms - getTermFromAmount(amount);
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> loadFeesConfig() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("financial_config")
          .get();

      final data = doc.data();
      if (data != null) {
        final loadedTotalFees = safeInt(data['totalFees']);
        final loadedTerms = safeInt(data['termCount']);

        if (loadedTotalFees > 0) {
          totalFees = loadedTotalFees;
        }

        if (loadedTerms > 0) {
          totalTerms = loadedTerms;
        }
      }
    } catch (_) {} finally {
      if (!mounted) return;
      setState(() => loadingConfig = false);
    }
  }

  Future<void> loadUsers() async {
    try {
      final snap = await FirebaseService.firestore
          .collection("users")
          .where("isVIP", isEqualTo: true)
          .get();

      users = snap.docs;

      for (var u in users) {
        final raw = u.data();
        final data = safeMap(raw);

        userNames[u.id] = safeString(data['name']).isEmpty
            ? "Student"
            : safeString(data['name']);
      }
    } catch (_) {} finally {
      if (!mounted) return;
      setState(() {
        loadingUser = false;
      });
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadFeesConfig();
    loadUsers();
  }

  Future<void> saveFeesConfig(int newTotalFees) async {
    final safeTotal = newTotalFees <= 0 ? totalFees : newTotalFees;
    final computedTermPrice = totalTerms <= 0 ? 0 : (safeTotal / totalTerms).round();

    try {
      setState(() {
        savingConfig = true;
      });

      await FirebaseService.firestore
          .collection("app_settings")
          .doc("financial_config")
          .set({
        "totalFees": safeTotal,
        "termCount": totalTerms,
        "termPrice": computedTermPrice,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      totalFees = safeTotal;

      if (mounted) {
        show("تم تحديث مصاريف السنتين ✅");
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        show("فشل حفظ المصاريف ❌");
      }
    } finally {
      if (!mounted) return;
      setState(() {
        savingConfig = false;
      });
    }
  }

  Future<void> addPayment(String userId) async {
    if (users.isEmpty) {
      show("لا يوجد طلاب VIP حالياً");
      return;
    }

    final amountController = TextEditingController();
    String localSelectedUserId = userId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text("إضافة دفعة",
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                      localSelectedUserId.isEmpty ? null : localSelectedUserId,
                  dropdownColor: AppColors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "اختر الطالب"),
                  items: users.map((u) {
                    return DropdownMenuItem<String>(
                      value: u.id,
                      child: Text(
                        userNames[u.id] ?? "Student",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      localSelectedUserId = val ?? "";
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "المبلغ"),
                ),
                const SizedBox(height: 8),
                Text(
                  "قيمة الترم الحالي: $termPrice جنيه",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  int amount = int.tryParse(amountController.text) ?? 0;

                  if (amount <= 0) {
                    return;
                  }
                  if (localSelectedUserId.isEmpty) {
                    return;
                  }

                  Navigator.pop(dialogCtx, {
                    "userId": localSelectedUserId,
                    "amount": amount,
                  });
                },
                child: const Text("حفظ"),
              )
            ],
          );
        },
      ),
    );

    amountController.dispose();

    if (result == null) return;

    _savePayment(result);
  }

  Future<void> _savePayment(Map<String, dynamic> data) async {
    await FirebaseService.firestore.collection("financial").add({
      "userId": safeString(data["userId"]),
      "amount": safeInt(data["amount"]),
      "timestamp": FieldValue.serverTimestamp(),
      "isVIP": true,
      "termPriceSnapshot": termPrice,
      "totalFeesSnapshot": totalFees,
      "termCountSnapshot": totalTerms,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إضافة الدفع ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser || loadingConfig) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("💰 إدارة المصاريف",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            onPressed: savingConfig
                ? null
                : () async {
                    final controller =
                        TextEditingController(text: totalFees.toString());

                    final result = await showDialog<int>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AppColors.black,
                        title: const Text(
                          "تعديل مصاريف السنتين",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "أدخل إجمالي المصاريف",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text("إلغاء"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              int v = int.tryParse(controller.text) ?? totalFees;
                              if (v <= 0) v = totalFees;
                              Navigator.pop(dialogCtx, v);
                            },
                            child: const Text("حفظ"),
                          ),
                        ],
                      ),
                    );

                    controller.dispose();

                    if (result != null) {
                      await saveFeesConfig(result);
                    }
                  },
            icon: savingConfig
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  )
                : const Icon(Icons.settings, color: AppColors.gold),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث...",
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => search = val.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _card("💵 إجمالي السنتين", "$totalFees جنيه"),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _card("📚 قيمة الترم", "$termPrice جنيه"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection("financial")
                .where("isVIP", isEqualTo: true)
                .snapshots(),
            builder: (context, snap) {
              int total = 0;
              int count = 0;

              if (snap.hasData) {
                for (var d in snap.data!.docs) {
                  final data = safeMap(d.data());
                  total += safeInt(data['amount']);
                }
                count = snap.data!.docs.length;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _card("💵 الإجمالي", "$total جنيه"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _card("📊 العمليات", "$count"),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection("financial")
                  .where("isVIP", isEqualTo: true)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      "📭 لا توجد معاملات مالية حالياً",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                Map<String, int> totals = {};

                for (var d in docs) {
                  final data = safeMap(d.data());

                  String uid = safeString(data['userId']);
                  int amount = safeInt(data['amount']);

                  if (uid.isEmpty) continue;

                  totals[uid] = (totals[uid] ?? 0) + amount;
                }

                final visibleUsers = users.where((u) {
                  final data = safeMap(u.data());
                  final name = safeString(data['name']).toLowerCase();
                  final email = safeString(data['email']).toLowerCase();
                  final phone = safeString(data['phone']).toLowerCase();

                  final searchLower = search.trim().toLowerCase();
                  return searchLower.isEmpty ||
                      name.contains(searchLower) ||
                      email.contains(searchLower) ||
                      phone.contains(searchLower);
                }).toList();

                visibleUsers.sort((a, b) {
                  final ad = safeMap(a.data());
                  final bd = safeMap(b.data());

                  final an = safeString(ad['name']).toLowerCase();
                  final bn = safeString(bd['name']).toLowerCase();

                  return an.compareTo(bn);
                });

                final totalStudents = users.length;
                final vipStudents = users.length;
                final blockedStudents = users.where((u) {
                  final data = safeMap(u.data());
                  return data['blocked'] == true;
                }).length;

                if (visibleUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 لا توجد نتائج",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        _card("إجمالي الطلاب", "$totalStudents",),
                        const SizedBox(width: 10),
                        _card("VIP", "$vipStudents"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _card("Blocked", "$blockedStudents"),
                        const SizedBox(width: 10),
                        _card("النتائج", "${visibleUsers.length}"),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...visibleUsers.map((u) {
                      final data = safeMap(u.data());

                      final courses = _listLength(data['enrolledCourses']);
                      final vip = _bool(data['isVIP']);
                      final blocked = _bool(data['blocked']);
                      final name = safeString(data['name']).isEmpty
                          ? "Student"
                          : safeString(data['name']);
                      final email = safeString(data['email']);
                      final phone = safeString(data['phone']);
                      final year = safeString(data['year']);
                      final term = safeString(data['term']);

                      final totalAmount = totals[u.id] ?? 0;
                      final completedTerms = getTermFromAmount(totalAmount);
                      final remainingAmount = getRemainingAmount(totalAmount);
                      final remainingTerms = getRemainingTerms(totalAmount);
                      final progressPercent = totalFees <= 0
                          ? 0.0
                          : (totalAmount / totalFees) * 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  if (email.isNotEmpty)
                                    Text(email,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  Text("💰 الإجمالي: $totalAmount جنيه",
                                      style: const TextStyle(
                                          color: Colors.green)),
                                  Text("📚 ترمات مكتملة: $completedTerms / $totalTerms",
                                      style: const TextStyle(color: Colors.orange)),
                                  Text("📉 المتبقي: $remainingAmount جنيه",
                                      style: const TextStyle(color: Colors.red)),
                                  Text("🧾 المتبقي ترمات: $remainingTerms",
                                      style: const TextStyle(color: Colors.blue)),
                                  if (progressPercent >= 100)
                                    const Text(
                                      "✅ تم السداد بالكامل",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  if (progressPercent < 100 && totalAmount > 0)
                                    Text(
                                      "📊 نسبة السداد: ${progressPercent.toStringAsFixed(1)}%",
                                      style: const TextStyle(color: Colors.white70),
                                    ),
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => addPayment(u.id),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}