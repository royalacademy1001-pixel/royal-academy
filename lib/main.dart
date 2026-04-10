import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'core/colors.dart';
import 'core/constants.dart';
import 'core/firebase_service.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/notification_service.dart';

import 'main_navigation_page.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'splash_page.dart';
import 'payment/payment_page.dart';
import 'payment/checkout_page.dart';
import 'features/courses/pages/courses_page.dart';
import 'student_profile_page.dart';
import 'web/verify_web_page.dart';
import 'features/quiz/student_quiz_page.dart';
import 'features/quiz/admin_add_quiz_page.dart';
import 'features/quiz/quiz_results_page.dart';

import 'admin/pages/admin_navigation_control_page.dart';
import 'admin/pages/analytics_dashboard_page.dart';
import 'admin/pages/attendance_report_page.dart';
import 'admin/pages/attendance_take_page.dart';
import 'admin/pages/comments_page.dart';
import 'features/center_management/pages/center_management_page.dart';
import 'admin/pages/courses_admin_page.dart';
import 'admin/pages/dashboard_page.dart';
import 'admin/pages/finance_reports_page.dart';
import 'admin/pages/instructor_requests_admin_page.dart';
import 'admin/pages/student_financial_details_page.dart';
import 'admin/pages/student_financial_page.dart';
import 'admin/pages/students_crm_page.dart';
import 'admin/pages/students_management_page.dart';
import 'admin/pages/subject_sessions_page.dart';
import 'admin/pages/subjects_page.dart';
import 'admin/pages/top_students_page.dart';
import 'admin/pages/verify_certificate_page.dart';

class AppGuard {
  static bool navigating = false;

  static void safeNavigate(VoidCallback action) {
    if (navigating) return;
    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("Navigation Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      navigating = false;
    });
  }
}

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _firebaseInitialized = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (!_firebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
    }
  } catch (e) {
    debugPrint("Background Error: $e");
  }
}

String _asString(dynamic value, [String fallback = ""]) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return {};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await FirebaseInit.init();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runZonedGuarded(() {
    runApp(const RoyalApp());
  }, (error, stack) {
    debugPrint("GLOBAL ERROR: $error");
  });
}

class RoyalApp extends StatefulWidget {
  const RoyalApp({super.key});

  @override
  State<RoyalApp> createState() => _RoyalAppState();
}

class _RoyalAppState extends State<RoyalApp> {
  bool initialized = false;
  bool showOnboarding = false;
  bool splashDone = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => splashDone = true);
      }
    });

    Future.microtask(_initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      await FirebaseInit.init();

      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint("Notification Error: $e");
      }

      try {
        await AnalyticsService.logEvent(type: "app_started");
      } catch (e) {
        debugPrint("Analytics Error: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool("seen_onboarding") ?? false;
      showOnboarding = !seen;
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      if (mounted) {
        setState(() => initialized = true);
      }
    }
  }

  Widget _authWrapper() {
    if (showOnboarding) {
      return OnboardingPage(
        onFinish: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("seen_onboarding", true);
          if (!mounted) return;
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
          return SplashPage();
        }

        if (snapshot.hasError) {
          return LoginPage();
        }

        if (snapshot.hasData) {
          return MainNavigationPage();
        }

        return LoginPage();
      },
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(builder: (_) => MainNavigationPage());

      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());

      case '/courses':
        return MaterialPageRoute(builder: (_) => const CoursesPage());

      case '/profile':
        return MaterialPageRoute(builder: (_) => const StudentProfilePage());

      case '/payment':
        return MaterialPageRoute(
          builder: (_) => PaymentPage(
            courseId: args is Map ? _asString(args['courseId']) : null,
          ),
        );

      case '/checkout':
        if (args is Map) {
          final map = _asMap(args);
          return MaterialPageRoute(
            builder: (_) => CheckoutPage(
              phone: _asString(map['phone']),
              price: int.tryParse(_asString(map['price'])) ?? 0,
              paid: int.tryParse(_asString(map['paid'])) ?? 0,
              remaining: int.tryParse(_asString(map['remaining'])) ?? 0,
              plan: _asString(map['plan']),
              courseId: _asString(map['courseId']).isEmpty
                  ? null
                  : _asString(map['courseId']),
              imageUrl: _asString(map['imageUrl']),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const CheckoutPage(
            phone: '',
            price: 0,
            paid: 0,
            remaining: 0,
            plan: '',
            courseId: null,
            imageUrl: '',
          ),
        );

      case '/verify':
        final certId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['certId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => VerifyCertificatePage(certId: certId),
        );

      case '/verifyWeb':
        final certId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['certId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => VerifyWebPage(certId: certId),
        );

      case '/quiz':
        final lessonId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['lessonId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => QuizPage(lessonId: lessonId),
        );

      case '/addQuiz':
        final lessonId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['lessonId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => AddQuizPage(lessonId: lessonId),
        );

      case '/quizResults':
        final lessonId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['lessonId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => QuizResultsPage(lessonId: lessonId),
        );

      case '/center':
        return MaterialPageRoute(builder: (_) => CenterManagementPage());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => DashboardPage());

      case '/analytics':
        return MaterialPageRoute(builder: (_) => AnalyticsDashboardPage());

      case '/attendanceTake':
        return MaterialPageRoute(builder: (_) => AttendanceTakePage());

      case '/attendanceReport':
        return MaterialPageRoute(builder: (_) => AttendanceReportPage());

      case '/subjects':
        return MaterialPageRoute(builder: (_) => SubjectsPage());

      case '/subjectSessions':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => SubjectSessionsPage(
              subjectId: _asString(args['subjectId']),
              subjectName: _asString(args['subjectName']),
            ),
          );
        }
        if (args is Map) {
          final map = _asMap(args);
          return MaterialPageRoute(
            builder: (_) => SubjectSessionsPage(
              subjectId: _asString(map['subjectId']),
              subjectName: _asString(map['subjectName']),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CenterManagementPage(),
        );

      case '/adminNavControl':
        return MaterialPageRoute(builder: (_) => AdminNavigationControlPage());

      case '/coursesAdmin':
        return MaterialPageRoute(builder: (_) => CoursesAdminPage());

      case '/studentsManagement':
        return MaterialPageRoute(builder: (_) => StudentsManagementPage());

      case '/studentsCrm':
        return MaterialPageRoute(builder: (_) => const StudentsCRMPage());

      case '/studentFinancial':
        return MaterialPageRoute(builder: (_) => StudentFinancialPage());

      case '/studentFinancialDetails':
        final userId = args is String
            ? args
            : args is Map
                ? _asString(_asMap(args)['userId'])
                : "";
        return MaterialPageRoute(
          builder: (_) => StudentFinancialDetailsPage(userId: userId),
        );

      case '/topStudents':
        return MaterialPageRoute(builder: (_) => TopStudentsPage());

      case '/comments':
        String lessonId = "";
        if (args is String) {
          lessonId = args;
        } else if (args is Map<String, dynamic>) {
          lessonId = _asString(args['lessonId']);
        } else if (args is Map) {
          lessonId = _asString(_asMap(args)['lessonId']);
        }
        return MaterialPageRoute(
          builder: (_) => CommentsPage(lessonId: lessonId),
        );

      case '/financeReports':
        return MaterialPageRoute(builder: (_) => FinanceReportsPage());

      case '/instructorRequests':
        return MaterialPageRoute(
          builder: (_) => InstructorRequestsAdminPage(),
        );

      default:
        return MaterialPageRoute(builder: (_) => SplashPage());
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: Brightness.dark,
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
      home: (!initialized || !splashDone) ? SplashPage() : _authWrapper(),
      onGenerateRoute: onGenerateRoute,
    );
  }
}