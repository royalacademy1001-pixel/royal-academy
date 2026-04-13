import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../core/colors.dart';

import '../core/analytics_service.dart';

import '../shared/widgets/custom_button.dart';
import '../shared/widgets/custom_textfield.dart';

import 'payment_service.dart';
import 'widgets/payment_widgets.dart';


class _PaymentGuard {
  static bool locked = false;
}

Widget paymentSafe(Widget child) {
  return RepaintBoundary(child: child);
}

class PaymentPage extends StatefulWidget {
  final String? courseId;
  const PaymentPage({super.key, this.courseId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  final phoneController = TextEditingController();
  final amountController = TextEditingController();

  String selectedPlan = AppConstants.planMonthly;
  int price = AppConstants.monthlyPrice;

  File? paymentImage;
  Uint8List? webImage;

  final picker = ImagePicker();

  String? selectedCourseId;
  String selectedCourseTitle = "";

  bool isLoading = false;
  bool isPartial = false;
  bool submitting = false;
  bool lockedUI = false;

  bool _hardLock = false;

  bool isAdmin = false;
  bool isVIP = false;
  bool checkingAdmin = true;

  Future<void> _checkAdmin() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      isAdmin = data['isAdmin'] == true;
      isVIP = data['isVIP'] == true;

    } catch (_) {}

    if (mounted) {
      setState(() => checkingAdmin = false);
    }
  }

  Future<void> _loadInitialCourse() async {
    if (widget.courseId == null) return;

    try {
      final doc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        selectedPlan = AppConstants.planSingleCourse;
        selectedCourseId = widget.courseId;
        selectedCourseTitle = data['title'] ?? "";
        price = int.tryParse(data['price']?.toString() ?? "0") ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _loadDynamicPrice() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .get();

      final data = doc.data() ?? {};

      if (selectedPlan == AppConstants.planMonthly) {
        price = int.tryParse(data['monthly']?.toString() ?? "") ?? AppConstants.monthlyPrice;
      }

      if (selectedPlan == AppConstants.planYearly) {
        price = int.tryParse(data['yearly']?.toString() ?? "") ?? AppConstants.yearlyPrice;
      }

    } catch (_) {}
  }

  Future pickImage() async {
    if (isLoading || lockedUI || _hardLock || _PaymentGuard.locked || isAdmin || isVIP) return;

    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      AnalyticsService.logEvent("pick_payment_image");

      if (kIsWeb) {
        webImage = await picked.readAsBytes();
      } else {
        paymentImage = File(picked.path);
      }

      if (!mounted) return;
      setState(() {});
      showSnack(context, "تم اختيار الصورة ✅");

    } catch (_) {
      showSnack(context, "خطأ في اختيار الصورة ❌", color: Colors.red);
    }
  }

  bool validate() {

    if (isAdmin || isVIP) {
      showSnack(context, "❌ غير مسموح للأدمن أو VIP بالدفع", color: Colors.red);
      return false;
    }

    String phone = phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      showSnack(context, "رقم الهاتف غير صحيح ❗", color: Colors.red);
      return false;
    }

    if (paymentImage == null && webImage == null) {
      showSnack(context, "ارفع صورة الدفع ❗", color: Colors.red);
      return false;
    }

    if (selectedPlan == AppConstants.planSingleCourse &&
        (selectedCourseId == null || price <= 0)) {
      showSnack(context, "اختر الكورس ❗", color: Colors.red);
      return false;
    }

    if (isPartial) {
      int entered = int.tryParse(amountController.text.trim()) ?? 0;

      if (entered <= 0) {
        showSnack(context, "المبلغ غير صحيح ❗", color: Colors.red);
        return false;
      }

      if (entered > price) {
        showSnack(context, "المبلغ أكبر من المطلوب ❗", color: Colors.red);
        return false;
      }
    }

    return true;
  }

  Future<bool> confirmPayment() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("تأكيد الدفع؟",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "تأكد من صحة البيانات قبل الإرسال",
          style: TextStyle(color: Colors.white70),
        ),
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

  Future submit() async {

    if (isAdmin || isVIP) {
      showSnack(context, "❌ غير مسموح للأدمن أو VIP بالدفع", color: Colors.red);
      return;
    }

    if (isLoading || submitting || lockedUI || _hardLock || _PaymentGuard.locked) return;

    _PaymentGuard.locked = true;
    _hardLock = true;
    lockedUI = true;
    submitting = true;

    var user = FirebaseService.auth.currentUser;
    if (user == null) {
      showSnack(context, "يجب تسجيل الدخول ❗", color: Colors.red);
      _unlock();
      return;
    }

    await _loadDynamicPrice();

    if (!validate()) {
      _unlock();
      return;
    }

    bool ok = await confirmPayment();
    if (!ok) {
      _unlock();
      return;
    }

    final effectiveCourseId = selectedCourseId ?? widget.courseId;

    int paid = isPartial
        ? (int.tryParse(amountController.text.trim()) ?? 0)
        : price;

    if (paid <= 0) {
      showSnack(context, "مبلغ غير صحيح ❗", color: Colors.red);
      _unlock();
      return;
    }

    if (paid > price) paid = price;

    int remaining = price - paid;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {

      String? imageUrl = await PaymentService.uploadImage(
        file: paymentImage,
        webImage: webImage,
      );

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("upload failed");
      }

      bool success = await PaymentService.submitPayment(
        userId: user.uid,
        email: user.email ?? "",
        phone: phoneController.text.trim(),
        plan: selectedPlan,
        price: price,
        paid: paid,
        remaining: remaining,
        courseId: effectiveCourseId,
        imageUrl: imageUrl,
      );

      if (!success) throw Exception("submit failed");

      await AnalyticsService.logPurchase(paid, courseId: effectiveCourseId);

      await AnalyticsService.logEvent(
        "payment_submitted",
        params: {
          "plan": selectedPlan,
          "price": price,
          "paid": paid,
          "courseId": effectiveCourseId ?? "none",
        },
      );

      if (!mounted) return;

      showSnack(context, "تم إرسال الطلب بنجاح 🎉");

      _resetForm();

    } catch (_) {
      if (mounted) {
        showSnack(context, "فشل العملية ❌", color: Colors.red);
      }
    }

    _unlock();

    if (mounted) setState(() => isLoading = false);
  }

  void _unlock() {
    submitting = false;
    lockedUI = false;
    _hardLock = false;
    _PaymentGuard.locked = false;
  }

  void _resetForm() {
    phoneController.clear();
    amountController.clear();

    setState(() {
      paymentImage = null;
      webImage = null;
      selectedCourseId = null;
      selectedCourseTitle = "";
      selectedPlan = AppConstants.planMonthly;
      price = AppConstants.monthlyPrice;
      isPartial = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    if (widget.courseId != null) {
      selectedPlan = AppConstants.planSingleCourse;
      selectedCourseId = widget.courseId;
      _loadInitialCourse();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (checkingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isAdmin || isVIP) {
      return const Scaffold(
        body: Center(
          child: Text(
            "❌ غير مسموح للأدمن أو VIP بالدفع",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    int paid = isPartial
        ? (int.tryParse(amountController.text.trim()) ?? 0)
        : price;

    if (paid > price) paid = price;

    int remaining = price - paid;

    return paymentSafe(
      Stack(
        children: [

          Scaffold(
            backgroundColor: AppColors.background,

            appBar: AppBar(
              title: const Text("💳 الدفع",
                  style: TextStyle(color: AppColors.gold)),
              backgroundColor: AppColors.black,
            ),

            body: AbsorbPointer(
              absorbing: isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: AppColors.premiumCard,
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: AppColors.gold),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "دفع آمن 100% 🔐",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("اختر الباقة",
                        style: TextStyle(color: AppColors.white)),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        buildPlan(
                          text: AppConstants.planMonthlyAr,
                          selected: selectedPlan == AppConstants.planMonthly,
                          onTap: () async {
                            selectedPlan = AppConstants.planMonthly;
                            await _loadDynamicPrice();
                            if (!mounted) return;
                            setState(() {
                              selectedCourseId = null;
                            });
                          },
                        ),
                        buildPlan(
                          text: AppConstants.planYearlyAr,
                          selected: selectedPlan == AppConstants.planYearly,
                          onTap: () async {
                            selectedPlan = AppConstants.planYearly;
                            await _loadDynamicPrice();
                            if (!mounted) return;
                            setState(() {
                              selectedCourseId = null;
                            });
                          },
                        ),
                        buildPlan(
                          text: AppConstants.planSingleCourseAr,
                          selected: selectedPlan == AppConstants.planSingleCourse,
                          onTap: () => setState(() {
                            selectedPlan = AppConstants.planSingleCourse;
                            price = 0;
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (selectedPlan == AppConstants.planSingleCourse)
                      courseSelector(
                        selectedId: selectedCourseId,
                        onSelect: (id) async {
                          var doc = await FirebaseService.firestore
                              .collection(AppConstants.courses)
                              .doc(id)
                              .get();

                          var data = doc.data() ?? {};

                          setState(() {
                            selectedCourseId = id;
                            selectedCourseTitle = data['title'] ?? "";
                            price = int.tryParse(data['price']?.toString() ?? "0") ?? 0;
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppColors.premiumCard.copyWith(
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: paymentSummary(
                        price: price,
                        paid: paid,
                        remaining: remaining,
                      ),
                    ),

                    const SizedBox(height: 20),

                    CustomTextField(
                      hint: "رقم الهاتف",
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    CustomButton(
                      text: "📸 رفع صورة الدفع",
                      onPressed: isLoading ? null : pickImage,
                    ),

                    if (webImage != null || paymentImage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: webImage != null
                              ? Image.memory(webImage!, height: 150, fit: BoxFit.cover)
                              : Image.file(paymentImage!, height: 150, fit: BoxFit.cover),
                        ),
                      ),

                    const SizedBox(height: 25),

                    CustomButton(
                      text: isLoading ? "جاري الإرسال..." : "🚀 تأكيد الدفع",
                      onPressed: (isLoading || submitting) ? null : submit,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}