import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

import '../../payment/payment_service.dart';

import 'payment_actions.dart';
import 'payment_filters.dart';

class PaymentsAdminPage extends StatefulWidget {

  final String initialStatus;

  const PaymentsAdminPage({
    super.key,
    this.initialStatus = "pending",
  });

  @override
  State<PaymentsAdminPage> createState() =>
      _PaymentsAdminPageState();
}

class _PaymentsAdminPageState extends State<PaymentsAdminPage> {

  late String statusFilter;

  String searchText = "";

  Timer? _debounce;

  Set<String> loadingIds = {};

  final monthlyController = TextEditingController();
  final yearlyController = TextEditingController();

  bool globalLock = false;

  @override
  void initState() {
    super.initState();

    statusFilter = widget.initialStatus;
    loadPrices();
  }

  Future<void> loadPrices() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .get();

      final data = doc.data() ?? {};

      monthlyController.text =
          (data['monthly'] ?? AppConstants.monthlyPrice).toString();

      yearlyController.text =
          (data['yearly'] ?? AppConstants.yearlyPrice).toString();

    } catch (_) {}
  }

  Future<void> savePrices() async {
    if (globalLock) return;
    globalLock = true;
    try {
      int monthly =
          int.tryParse(monthlyController.text.trim()) ??
              AppConstants.monthlyPrice;

      int yearly =
          int.tryParse(yearlyController.text.trim()) ??
              AppConstants.yearlyPrice;

      await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .set({
        "monthly": monthly,
        "yearly": yearly,
      }, SetOptions(merge: true));

      show("تم تحديث الأسعار بنجاح ✅");

    } catch (_) {
      show("❌ فشل تحديث الأسعار", error: true);
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      globalLock = false;
    });
  }

  void onSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => searchText = val.toLowerCase().trim());
      }
    });
  }

  void show(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> confirm(String text) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    monthlyController.dispose();
    yearlyController.dispose();
    super.dispose();
  }

  Future<void> handleAction({
    required String id,
    required Future<void> Function() action,
    required String successMsg,
  }) async {

    if (loadingIds.contains(id)) return;
    if (globalLock) return;

    globalLock = true;

    setState(() => loadingIds.add(id));

    try {
      await action();
      show(successMsg);
    } catch (e) {
      debugPrint("Action Error: $e");
      show("❌ حصل خطأ", error: true);
    }

    if (mounted) {
      setState(() => loadingIds.remove(id));
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      globalLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final currentUserId = FirebaseService.auth.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseService.firestore.collection(AppConstants.users).doc(currentUserId).get(),
      builder: (context, adminSnap) {

        if (!adminSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final adminData = adminSnap.data!.data() as Map<String, dynamic>? ?? {};
        final isCurrentAdmin = adminData['isAdmin'] == true;

        if (!isCurrentAdmin) {
          return const Scaffold(
            body: Center(
              child: Text("غير مسموح بالدخول", style: TextStyle(color: Colors.white)),
            ),
            backgroundColor: AppColors.background,
          );
        }

        return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("💰 إدارة المدفوعات",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: AppColors.premiumCard,
              child: Column(
                children: [

                  const Text("⚙ تعديل الأسعار",
                      style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  TextField(
                    controller: monthlyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "سعر الاشتراك الشهري",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: yearlyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "سعر الاشتراك السنوي",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: globalLock ? null : savePrices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    child: const Text("💾 حفظ التعديلات",
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.payments)
                  .orderBy("createdAt", descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold),
                  );
                }

                final docs = snapshot.data!.docs;

                final payments = PaymentFilters.filter(
                  docs: docs,
                  status: statusFilter,
                  query: searchText,
                );

                return Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        onChanged: onSearch,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "🔍 بحث بالبريد",
                          filled: true,
                          fillColor: AppColors.black,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        filterBtn("pending", "Pending"),
                        filterBtn("approved", "Approved"),
                        filterBtn("rejected", "Rejected"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: payments.isEmpty
                          ? const Center(
                              child: Text("لا يوجد بيانات",
                                  style: TextStyle(color: Colors.white)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: payments.length,
                              itemBuilder: (context, index) {

                                final doc = payments[index];
                                final data = doc.data();

                                final email = (data['email'] ?? "").toString();
                                final status = (data['status'] ?? "pending").toString();

                                final price = data['price'] ?? 0;
                                final paid = data['paid'] ?? 0;
                                final remaining = data['remaining'] ?? 0;

                                final image = (data['imageUrl'] ?? "").toString();
                                final courseId = (data['courseId'] ?? "").toString();
                                final userId = (data['userId'] ?? "").toString();

                                final isLoading = loadingIds.contains(doc.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(15),
                                  decoration: AppColors.premiumCard,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        email.isEmpty ? "No Email" : email,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        "💰 $paid / $price",
                                        style: const TextStyle(color: Colors.green),
                                      ),

                                      if (remaining > 0)
                                        Text(
                                          "المتبقي: $remaining",
                                          style: const TextStyle(color: Colors.orange),
                                        ),

                                      const SizedBox(height: 10),

                                      if (image.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: Image.network(image),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              image,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [

                                          buildStatus(status),

                                          if (status == "pending")
                                            isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(),
                                                  )
                                                : Row(
                                                    children: [

                                                      IconButton(
                                                        icon: const Icon(Icons.check,
                                                            color: Colors.green),
                                                        onPressed: (globalLock || isLoading) ? null : () async {

                                                          bool ok = await confirm("تأكيد القبول؟");
                                                          if (!ok) return;

                                                          await handleAction(
                                                            id: doc.id,
                                                            action: () async {
                                                              await PaymentService.approvePayment(
                                                                paymentId: doc.id,
                                                                data: data,
                                                              );
                                                            },
                                                            successMsg: "تم القبول وفتح الكورس ✅🔥",
                                                          );
                                                        },
                                                      ),

                                                      IconButton(
                                                        icon: const Icon(Icons.close,
                                                            color: Colors.red),
                                                        onPressed: (globalLock || isLoading) ? null : () async {

                                                          bool ok = await confirm("تأكيد الرفض؟");
                                                          if (!ok) return;

                                                          await handleAction(
                                                            id: doc.id,
                                                            action: () => PaymentService.rejectPayment(doc.id),
                                                            successMsg: "تم الرفض ❌",
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [

                                          Text(
                                            "Course: $courseId",
                                            style: const TextStyle(color: Colors.grey),
                                          ),

                                          Text(
                                            "User: $userId",
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget filterBtn(String value, String text) {
    bool selected = value == statusFilter;

    return GestureDetector(
      onTap: () => setState(() => statusFilter = value),
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(
            horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildStatus(String status) {
    switch (status) {
      case "approved":
        return const Text("✅ Approved",
            style: TextStyle(color: Colors.green));
      case "rejected":
        return const Text("❌ Rejected",
            style: TextStyle(color: Colors.red));
      default:
        return const Text("⏳ Pending",
            style: TextStyle(color: Colors.orange));
    }
  }
}