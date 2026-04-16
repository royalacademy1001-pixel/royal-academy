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

    notificationStream = FirebaseService.firestore
        .collection(AppConstants.notifications)
        .snapshots();

    AnalyticsService.logScreen("home");

    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 300) {
        AnalyticsService.logEvent("home_scroll_deep");
      }
    });

    _init();
  }

  Future<void> _init() async {
    try {
      await PermissionService.load();

      final user = FirebaseService.auth.currentUser;

      if (user == null) {
        _role = "guest";
        _allowed = PermissionService.canAccess(role: _role, page: "home");

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

      _role = PermissionService.getRole(data);
      _allowed = PermissionService.canAccess(role: _role, page: "home");

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
          _allowed = false;
        });
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
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
                      HomeHero(
                        userName: userName,
                        onStartTap: () {
                          AnalyticsService.logEvent("home_start_clicked");
                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/courses');
                        },
                      ),
                      HomeVipCard(
                        isAdmin: isAdmin,
                        isVIP: isVIP,
                        subscribed: subscribed,
                      ),
                      HomeStatsCard(
                        isAdmin: isAdmin,
                        isVIP: isVIP,
                        subscribed: subscribed,
                        userXP: userXP,
                        streak: streak,
                      ),
                      HomeGrid(
                        isAdmin: isAdmin,
                        isInstructor: isInstructor,
                      ),
                      if (isAdmin) const RepaintBoundary(child: HomeAdminSection()),
                      const RepaintBoundary(child: HomeNewsSection()),
                      const RepaintBoundary(child: HomeContinueWatchingSection()),
                      const RepaintBoundary(child: HomeRecommendedSection()),
                      const RepaintBoundary(child: HomeCoursesSection()),
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
  }
}