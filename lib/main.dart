// 🔥 ULTRA MAIN (FIXED FINAL - NO CRASH)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

// 🔥 Core
import 'core/firebase_service.dart';
import 'core/colors.dart';
import 'core/constants.dart';
import 'core/notifications_service.dart';

// 🔥🔥🔥 NEW ANALYTICS
import 'core/analytics_service.dart';

// 🔥 Pages
import 'main_navigation_page.dart';
import 'login_page.dart';
import 'splash_page.dart';
import 'payment/payment_page.dart';
import 'onboarding_page.dart';

// 🔥 VERIFY
import 'admin/pages/verify_certificate_page.dart';

// 🔥 QUIZ RESULTS
import 'features/quiz/quiz_results_page.dart';

// 🔥 WEB
import 'web/verify_web_page.dart';


/// 🔥 GUARD
class AppGuard {
  static bool navigating = false;

  static void safeNavigate(VoidCallback action) {
    if (navigating) return;
    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("🔥 Navigation Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      navigating = false;
    });
  }
}

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

bool _firebaseInitialized = false;

/// ================= BACKGROUND =================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (!_firebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
    }
  } catch (e) {
    debugPrint("🔥 Background Error: $e");
  }
}

/// ================= MAIN =================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await AnalyticsService.init();
    await AnalyticsService.logEvent("app_open");

    FirebaseService.firestore.collection("analytics_events").add({
      "type": "app_open",
      "userId": FirebaseService.auth.currentUser?.uid ?? "",
      "timestamp": Timestamp.now(),
    });

  } catch (e) {
    debugPrint("🔥 Analytics Init Error: $e");
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);
  }

  runApp(const RoyalApp());
}

/// ================= APP =================
class RoyalApp extends StatefulWidget {
  const RoyalApp({super.key});

  @override
  State<RoyalApp> createState() => _RoyalAppState();
}

class _RoyalAppState extends State<RoyalApp> {

  bool initialized = false;
  bool showOnboarding = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      try {
        if (!kIsWeb) {
          await NotificationsService.init();

          await FirebaseMessaging.instance.requestPermission();

          String? token = await FirebaseMessaging.instance.getToken();

          if (token != null) {
            final user = FirebaseService.auth.currentUser;
            if (user != null) {
              await FirebaseService.firestore
                  .collection(AppConstants.users)
                  .doc(user.uid)
                  .set({
                "fcmToken": token,
              }, SetOptions(merge: true));
            }
          }

          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            if (message.notification != null) {
              messengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    message.notification?.title ?? "New Notification",
                  ),
                ),
              );
            }
          });
        }

        await AnalyticsService.logEvent("app_started");
        await AnalyticsService.trackUserActive();

        FirebaseService.firestore.collection("analytics_events").add({
          "type": "app_started",
          "userId": FirebaseService.auth.currentUser?.uid ?? "",
          "timestamp": Timestamp.now(),
        });

        final prefs = await SharedPreferences.getInstance();
        bool seen = prefs.getBool("seen_onboarding") ?? false;

        showOnboarding = !seen;

      } catch (e) {
        debugPrint("🔥 Init Error: $e");
      }

      if (mounted) {
        setState(() => initialized = true);
      }
    });
  }

  Widget _authWrapper() {
    if (showOnboarding) {
      return OnboardingPage(
        onFinish: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("seen_onboarding", true);
          setState(() {
            showOnboarding = false;
          });
        },
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        if (snapshot.hasData) {
          return const MainNavigationPage();
        }

        return const LoginPage();
      },
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {

    switch (settings.name) {

      case '/home':
        return MaterialPageRoute(
            builder: (_) => const MainNavigationPage());

      case '/login':
        return MaterialPageRoute(
            builder: (_) => const LoginPage());

      case '/payment':
        return MaterialPageRoute(
            builder: (_) => const PaymentPage());

      case '/verify':
        final certId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) =>
                VerifyCertificatePage(certId: certId ?? ""));

      case '/quizResults':
        final lessonId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) =>
                QuizResultsPage(lessonId: lessonId ?? ""));

      case '/verifyWeb':
        final certId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) =>
                VerifyWebPage(certId: certId ?? ""));

      default:
        return MaterialPageRoute(
            builder: (_) => const SplashPage());
    }
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: "Royal Academy",
      theme: _darkTheme(),
      home: initialized ? _authWrapper() : const SplashPage(),
      onGenerateRoute: onGenerateRoute,
    );
  }
}