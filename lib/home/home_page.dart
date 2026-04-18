import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/permission_service.dart';
import '../shared/services/analytics_service.dart';

import 'widgets/home_hero.dart';
import 'widgets/home_stats_card.dart';
import 'widgets/home_vip_card.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_news_section.dart';
import 'widgets/home_courses_section.dart';
import 'widgets/home_recommended_section.dart';
import 'widgets/home_continue_watching_section.dart';
import 'widgets/home_admin_section.dart';
import 'widgets/home_notification_icon.dart';
import 'widgets/home_skeleton.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _lastLoadTime;
  static bool _builtOnce = false;
  static String? _cachedUid;

  static List<String>? _cachedLayout;
  static DateTime? _layoutTime;

  Map<String, dynamic>? userData;
  Stream<QuerySnapshot>? notificationStream;
  final ScrollController _scrollController = ScrollController();
  bool loading = true;
  bool _disposed = false;
  bool _permissionReady = false;
  bool _allowed = false;
  String _role = "guest";

  bool get isAdmin => userData?['isAdmin'] == true;
  bool get isVIP => userData?['isVIP'] == true;
  bool get subscribed => userData?['subscribed'] == true;
  bool get isInstructor => userData?['instructorApproved'] == true;

  int get userXP => (userData?['xp'] ?? 0) is int
      ? (userData?['xp'] ?? 0)
      : int.tryParse((userData?['xp'] ?? "0").toString()) ?? 0;

  int get streak => (userData?['streak'] ?? 0) is int
      ? (userData?['streak'] ?? 0)
      : int.tryParse((userData?['streak'] ?? "0").toString()) ?? 0;

  @override
  void initState() {
    super.initState();

    final currentUid = FirebaseService.auth.currentUser?.uid;
    if (_cachedUid != null && currentUid != null && _cachedUid != currentUid) {
      _cachedUserData = null;
      _lastLoadTime = null;
      _builtOnce = false;
      _cachedUid = currentUid;
    }

    notificationStream = FirebaseService.firestore
        .collection(AppConstants.notifications)
        .snapshots();

    AnalyticsService.logScreen("home");

    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 300) {
        AnalyticsService.logEvent("home_scroll_deep");
      }
    });

    if (_cachedUserData != null && !_builtOnce) {
      userData = Map<String, dynamic>.from(_cachedUserData!);
      _role = PermissionService.getRole(userData);
      _allowed = true;
      loading = false;
      _permissionReady = true;
      _builtOnce = true;
    }

    _init();
  }

  Future<void> _init() async {
    try {
      await PermissionService.load();

      final now = DateTime.now();
      final currentUid = FirebaseService.auth.currentUser?.uid;

      if (_cachedUid != currentUid) {
        _cachedUserData = null;
        _lastLoadTime = null;
        _builtOnce = false;
        _cachedUid = currentUid;
      }

      if (_cachedUserData != null &&
          _lastLoadTime != null &&
          now.difference(_lastLoadTime!).inSeconds < 60) {
        userData = Map<String, dynamic>.from(_cachedUserData!);
        _role = PermissionService.getRole(userData);
        _allowed = true;

        if (!_disposed && mounted) {
          setState(() {
            loading = false;
            _permissionReady = true;
          });
        }
        return;
      }

      final user = FirebaseService.auth.currentUser;

      if (user == null) {
        _role = "guest";
        _allowed = true;

        if (!_disposed && mounted) {
          setState(() {
            userData = {};
            loading = false;
            _permissionReady = true;
          });
        }
        return;
      }

      final data = await FirebaseService.getUserData();

      if (_disposed || !mounted) return;

      userData = data;
      _cachedUserData = Map<String, dynamic>.from(data);
      _lastLoadTime = DateTime.now();
      _cachedUid = user.uid;

      _role = PermissionService.getRole(data);
      _allowed = true;

      AnalyticsService.logEvent("home_loaded", params: {
        "isAdmin": isAdmin,
        "isVIP": isVIP,
        "subscribed": subscribed,
      });

      if (notificationStream == null) {
        notificationStream = FirebaseService.firestore
            .collection(AppConstants.notifications)
            .snapshots();
      }

      if (!_disposed && mounted) {
        setState(() {
          loading = false;
          _permissionReady = true;
        });
      }
    } catch (_) {
      if (!_disposed && mounted) {
        setState(() {
          userData = {};
          loading = false;
          _permissionReady = true;
          _allowed = true;
        });
      }
    }
  }

  Future<List<String>> _getLayout() async {
    final now = DateTime.now();

    if (_cachedLayout != null &&
        _layoutTime != null &&
        now.difference(_layoutTime!).inSeconds < 60) {
      return _cachedLayout!;
    }

    try {
      final doc = await FirebaseService.firestore
          .collection("app_settings")
          .doc("home_layout")
          .get();

      final data = doc.data();

      if (data != null && data['items'] is List) {
        final raw = data['items'] as List;

        final List<String> layout = [];

        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            final id = (e['id'] ?? "").toString();
            final enabled = e['enabled'] == true;

            if (id.isNotEmpty && enabled) {
              layout.add(id);
            }
          }
        }

        if (layout.isNotEmpty) {
          _cachedLayout = layout;
          _layoutTime = DateTime.now();
          return layout;
        }
      }
    } catch (_) {}

    return [
      "hero",
      "vip",
      "stats",
      "grid",
      "admin",
      "news",
      "continue",
      "recommended",
      "courses",
    ];
  }

  Widget _buildSection(String id, String userName) {
    switch (id) {
      case "hero":
        return HomeHero(
          userName: userName,
          onStartTap: () {
            AnalyticsService.logEvent("home_start_clicked");
            if (!context.mounted) return;
            Navigator.pushNamed(context, '/courses');
          },
        );

      case "vip":
        return HomeVipCard(
          isAdmin: isAdmin,
          isVIP: isVIP,
          subscribed: subscribed,
        );

      case "stats":
        return HomeStatsCard(
          isAdmin: isAdmin,
          isVIP: isVIP,
          subscribed: subscribed,
          userXP: userXP,
          streak: streak,
        );

      case "grid":
        return HomeGrid(
          isAdmin: isAdmin,
          isInstructor: isInstructor,
        );

      case "admin":
        if (!isAdmin) return const SizedBox();
        return const RepaintBoundary(child: HomeAdminSection());

      case "news":
        return const RepaintBoundary(child: HomeNewsSection());

      case "continue":
        return const RepaintBoundary(child: HomeContinueWatchingSection());

      case "recommended":
        return const RepaintBoundary(child: HomeRecommendedSection());

      case "courses":
        return const RepaintBoundary(child: HomeCoursesSection());

      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  double _getMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1100) return 1100;
    if (width > 800) return 800;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading || !_permissionReady) {
      return const HomeSkeleton();
    }

    if (!_allowed) {
      return const Scaffold(
        body: Center(
          child: Text("🚫 غير مسموح بالدخول"),
        ),
      );
    }

    final currentUserData = userData ?? {};

    final String userName =
        (currentUserData['name'] ?? currentUserData['displayName'] ?? "أهلاً بيك")
            .toString();

    final maxWidth = _getMaxWidth(context);

    return FutureBuilder<List<String>>(
      future: _getLayout(),
      builder: (context, snapshot) {
        final layout = snapshot.data ??
            [
              "hero",
              "vip",
              "stats",
              "grid",
              "admin",
              "news",
              "continue",
              "recommended",
              "courses",
            ];

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                cacheExtent: 3000,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    actions: [
                      HomeNotificationIcon(stream: notificationStream),
                      const SizedBox(width: 10),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...layout.map((id) => _buildSection(id, userName)),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}