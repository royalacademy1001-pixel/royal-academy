import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';

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
    _init();
  }

  Future<void> _init() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => loading = false);
        }
        return;
      }

      final data = await FirebaseService.getUserData();

      if (!mounted) return;

      userData = data;

      notificationStream = FirebaseService.firestore
          .collection(AppConstants.notifications)
          .snapshots();

      setState(() => loading = false);
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading || userData == null) {
      return const HomeSkeleton();
    }

    final String userName =
        (userData!['name'] ?? userData!['displayName'] ?? "أهلاً بيك")
            .toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHero(
                  userName: userName,
                  onStartTap: () {
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
                if (isAdmin) HomeAdminSection(),
                const HomeNewsSection(),
                const HomeContinueWatchingSection(),
                const HomeRecommendedSection(),
                const HomeCoursesSection(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}