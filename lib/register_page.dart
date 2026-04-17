// 🔥 FINAL REGISTER PAGE (PRO MAX++ ENTERPRISE FINAL SAFE - NO DELETE)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/colors.dart';
import 'shared/widgets/custom_button.dart';
import 'shared/widgets/custom_textfield.dart';

// 🔥🔥🔥 NEW ANALYTICS
import 'core/analytics_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  DateTime? _lastRegisterAttempt;

  bool validate() {
    final n = name.text.trim();
    final p = phone.text.trim();
    final e = email.text.trim().toLowerCase();
    final pass = password.text.trim();
    final confirm = confirmPassword.text.trim();

    final emailRegex =
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

    if (n.isEmpty || p.isEmpty || e.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showSnack("كمل البيانات ❗", Colors.red);
      return false;
    }

    if (n.length < 3) {
      showSnack("الاسم قصير ❗", Colors.red);
      return false;
    }

    if (p.length < 10) {
      showSnack("رقم الهاتف غير صحيح ❗", Colors.red);
      return false;
    }

    if (!emailRegex.hasMatch(e)) {
      showSnack("إيميل غير صحيح ❌", Colors.red);
      return false;
    }

    if (pass.length < 6) {
      showSnack("كلمة المرور ضعيفة ❌", Colors.red);
      return false;
    }

    if (pass != confirm) {
      showSnack("كلمة المرور غير متطابقة ❌", Colors.red);
      return false;
    }

    return true;
  }

  Future<bool> hasInternet() async {
    try {
      if (kIsWeb) return true;
      var result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }

  Future<void> register() async {

    if (loading) return;

    if (_lastRegisterAttempt != null &&
        DateTime.now().difference(_lastRegisterAttempt!).inSeconds < 2) {
      return;
    }
    _lastRegisterAttempt = DateTime.now();

    FocusScope.of(context).unfocus();

    if (!validate()) return;

    if (!await hasInternet()) {
      showSnack("لا يوجد اتصال بالإنترنت ❌", Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);

    try {

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim().toLowerCase(),
        password: password.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({

        "name": name.text.trim(),
        "phone": phone.text.trim(),
        "email": email.text.trim().toLowerCase(),

        "blocked": false,
        "isAdmin": false,

        "subscribed": false,
        "subscriptionEnd": null,
        "subscriptionStatus": "inactive",

        "enrolledCourses": [],
        "unlockedCourses": [],

        "lastCourseId": null,
        "lastLessonId": null,
        "lastVideoTitle": null,

        "role": "user",
        "accountType": "user",

        "instructorRequest": false,
        "instructorApproved": false,

        "fcmTokens": [],
        "deviceInfo": {
          "platform": kIsWeb ? "web" : "mobile",
        },

        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),

      });

      await AnalyticsService.logRegister();

      if (!mounted) return;

      showSnack("تم إنشاء الحساب بنجاح ✅", Colors.green);

      try {
        TextInput.finishAutofillContext();
      } catch (_) {}

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false,
      );

    } on FirebaseAuthException catch (e) {

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = "الإيميل مستخدم بالفعل ❌";
          break;
        case 'weak-password':
          message = "كلمة المرور ضعيفة ❌";
          break;
        case 'invalid-email':
          message = "إيميل غير صالح ❌";
          break;
        case 'network-request-failed':
          message = "مشكلة في الإنترنت ❌";
          break;
        default:
          message = "حدث خطأ ❌";
      }

      showSnack(message, Colors.red);

    } catch (_) {

      try {
        final user = FirebaseAuth.instance.currentUser;
        await user?.delete();
      } catch (_) {}

      showSnack("فشل إنشاء الحساب ❌", Colors.red);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void showSnack(String text, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
        content: Text(text, style: TextStyle(color: color)),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();

    nameFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    confirmFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Color(0xFF1A1A1A),
                    Colors.black,
                  ],
                ),
              ),
            ),

            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.05),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AutofillGroup(
                child: Column(
                  children: [

                    const SizedBox(height: 80),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 40,
                          )
                        ],
                      ),
                      child: Image.asset(
                        "assets/logo.png",
                        height: 100,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school,
                          color: Colors.amber,
                          size: 80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "إنشاء حساب جديد",
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "ابدأ رحلتك التعليمية الآن 🚀",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppColors.glassDecoration,
                      child: Column(
                        children: [

                          CustomTextField(
                            hint: "الاسم",
                            controller: name,
                            focusNode: nameFocus,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(phoneFocus),
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hint: "رقم الموبايل",
                            controller: phone,
                            focusNode: phoneFocus,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.telephoneNumber],
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(emailFocus),
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hint: "البريد الإلكتروني",
                            controller: email,
                            focusNode: emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(passFocus),
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hint: "كلمة المرور",
                            controller: password,
                            focusNode: passFocus,
                            isPassword: obscure1,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(confirmFocus),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure1
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.gold,
                              ),
                              onPressed: () {
                                setState(() => obscure1 = !obscure1);
                              },
                            ),
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hint: "تأكيد كلمة المرور",
                            controller: confirmPassword,
                            focusNode: confirmFocus,
                            isPassword: obscure2,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => register(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure2
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.gold,
                              ),
                              onPressed: () {
                                setState(() => obscure2 = !obscure2);
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          CustomButton(
                            text: "إنشاء الحساب",
                            onPressed: register,
                            isLoading: loading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            if (loading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}