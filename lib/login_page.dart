// 🔥 FINAL LOGIN PAGE (PRO MAX++ ENTERPRISE FINAL SAFE - NO DELETE)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_page.dart';
import 'core/colors.dart';
import 'shared/widgets/custom_button.dart';
import 'shared/widgets/custom_textfield.dart';

// 🔥🔥🔥 NEW (ANALYTICS)
import 'core/analytics_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final email = TextEditingController();
  final password = TextEditingController();

  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  bool loading = false;
  bool obscure = true;
  bool remember = true;

  bool _pressed = false;

  DateTime? _lastLoginAttempt;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString("saved_email");

      if (saved != null && saved.isNotEmpty) {
        email.text = saved;
      }
    } catch (_) {}
  }

  Future<void> _saveEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (remember) {
        await prefs.setString("saved_email", email.text.trim());
      } else {
        await prefs.remove("saved_email");
      }
    } catch (_) {}
  }

  bool validate() {
    final e = email.text.trim();
    final p = password.text.trim();

    final emailRegex =
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

    if (e.isEmpty || p.isEmpty) {
      showSnack("من فضلك أكمل البيانات ❗", Colors.red);
      return false;
    }

    if (!emailRegex.hasMatch(e)) {
      showSnack("البريد الإلكتروني غير صحيح ❗", Colors.red);
      return false;
    }

    if (p.length < 6) {
      showSnack("كلمة المرور قصيرة ❗", Colors.red);
      return false;
    }

    return true;
  }

  Future<bool> hasInternet() async {
    try {
      if (kIsWeb) return true;

      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;

    } catch (_) {
      return true;
    }
  }

  Future<void> login() async {

    if (loading || _pressed) return;

    _pressed = true;

    if (_lastLoginAttempt != null &&
        DateTime.now().difference(_lastLoginAttempt!).inSeconds < 2) {
      _pressed = false;
      return;
    }
    _lastLoginAttempt = DateTime.now();

    FocusScope.of(context).unfocus();

    if (!validate()) {
      _pressed = false;
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);

    if (!await hasInternet()) {
      if (mounted) setState(() => loading = false);
      _pressed = false;
      showSnack("أنت غير متصل بالإنترنت ❌", Colors.red);
      return;
    }

    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim().toLowerCase(),
        password: password.text.trim(),
      );

      await _saveEmail();

      await AnalyticsService.logLogin();

      if (!mounted) return;

      try {
        TextInput.finishAutofillContext();
      } catch (_) {}

      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
        );
      });

    } on FirebaseAuthException catch (e) {

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "لا يوجد حساب بهذا البريد ❌";
          break;
        case 'wrong-password':
          message = "كلمة المرور غير صحيحة ❌";
          break;
        case 'invalid-email':
          message = "البريد الإلكتروني غير صالح ❌";
          break;
        case 'user-disabled':
          message = "تم إيقاف الحساب ❌";
          break;
        case 'too-many-requests':
          message = "محاولات كثيرة.. حاول لاحقًا ⏳";
          break;
        case 'network-request-failed':
          message = "مشكلة في الاتصال ❌";
          break;
        case 'invalid-credential':
          message = "الإيميل أو الباسورد غير صحيح ❌";
          break;
        default:
          message = "حدث خطأ ❌";
      }

      showSnack(message, Colors.red);

    } catch (_) {
      showSnack("خطأ غير متوقع ❌", Colors.red);
    }

    if (mounted) {
      setState(() => loading = false);
    }

    _pressed = false;
  }

  Future<void> resetPassword() async {

    if (email.text.trim().isEmpty) {
      showSnack("اكتب البريد الإلكتروني أولاً 📧", Colors.red);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      showSnack("تم إرسال رابط الاستعادة 📩", Colors.green);

    } catch (_) {
      showSnack("فشل إرسال الرابط ❌", Colors.red);
    }
  }

  void showSnack(String text, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        content: Text(text, style: TextStyle(color: color)),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passFocus.dispose();
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
              right: -80,
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
              left: -80,
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

                    const SizedBox(height: 90),

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
                        height: 110,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school,
                          color: Colors.amber,
                          size: 80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "مرحباً بك 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "سجل الدخول لمتابعة التعلم",
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
                            hint: "البريد الإلكتروني",
                            controller: email,
                            focusNode: emailFocus,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(passFocus);
                            },
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hint: "كلمة المرور",
                            controller: password,
                            focusNode: passFocus,
                            isPassword: obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => login(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                            ),
                          ),

                          Row(
                            children: [
                              Checkbox(
                                value: remember,
                                onChanged: (bool? v) =>
                                    setState(() => remember = v ?? false),
                                activeColor: AppColors.gold,
                              ),
                              const Text(
                                "تذكرني",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: resetPassword,
                              child: const Text(
                                "نسيت كلمة المرور؟",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          CustomButton(
                            text: "تسجيل الدخول",
                            onPressed: login,
                            isLoading: loading,
                          ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterPage()),
                              );
                            },
                            child: const Text(
                              "إنشاء حساب جديد",
                              style: TextStyle(color: AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                    ),
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