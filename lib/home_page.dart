import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'courses_page.dart';
import 'payment/payment_page.dart';
import 'notifications/notifications_page.dart';
import 'leaderboard_page.dart';
import 'admin/admin_page.dart';

import '../widgets/course_card.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

class _NavGuard {
  static bool navigating = false;

  static void go(VoidCallback action) {
    if (navigating) return;
    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("🔥 Nav Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      navigating = false;
    });
  }
}

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    userData = await FirebaseService.getUserData();

    notificationStream = FirebaseService.firestore
        .collection(AppConstants.notifications)
        .snapshots();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _refresh() async {
    userData = await FirebaseService.getUserData(refresh: true);
    if (mounted) setState(() {});
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "صباح الخير ☀️";
    if (h < 18) return "مساء الخير 🌤";
    return "مساء الخير 🌙";
  }

  bool _isVisibleCourse(Map<String, dynamic> data) {
    final approved = data['approved'] == true;
    final status = (data['status'] ?? "").toString().toLowerCase();
    return approved || status == "approved";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    if (loading || userData == null) {
      return _skeleton();
    }

    final bool isAdmin = userData!['isAdmin'] == true;
    final bool isVIP = userData!['isVIP'] == true;
    final bool subscribed = userData!['subscribed'] == true;
    final String userName =
        (userData!['name'] ?? userData!['displayName'] ?? "أهلاً بيك").toString();
    final int userXP = userData!['xp'] ?? 0;
    final int streak = userData!['streak'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.gold,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 105,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    title: Text(
                      greeting(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  actions: [
                    _notificationIcon(),
                    const SizedBox(width: 10),
                  ],
                ),
                SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(userName),
                        _vipCard(isAdmin, subscribed, isVIP),
                        _statsCard(isAdmin, subscribed, isVIP, userXP, streak),
                        if (!subscribed && !isAdmin && !isVIP) _subscribeBanner(),
                        _newsSection(),
                        _continueWatching(),
                        _recommended(),
                        _title("🔥 الأكثر مشاهدة"),
                        _courses(),
                        const SizedBox(height: 20),
                        _title("⚡ الوصول السريع"),
                        _grid(isAdmin),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection("news")
          .orderBy("createdAt", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("📰 آخر الأخبار"),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final image = FirebaseService.fixImage((data['image'] ?? "").toString());
                  final title = (data['title'] ?? "").toString();

                  return GestureDetector(
                    onTap: () => _showNewsDetails(title, image),
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        color: const Color(0xFF151515),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: image.isEmpty
                                  ? Container(color: const Color(0xFF1A1A1A))
                                  : CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: const Color(0xFF1A1A1A),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 15,
                              left: 15,
                              bottom: 15,
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewsDetails(String title, String image) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: AppColors.black.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: notificationStream,
      builder: (context, snapshot) {
        final user = FirebaseService.auth.currentUser;
        int count = 0;
        if (snapshot.hasData && user != null) {
          count = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['userId'] == user.uid || data['type'] == "all") && !(data['seen'] ?? false);
          }).length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            _glassActionBtn(Icons.notifications_none_rounded, () {
              _NavGuard.go(() => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ));
            }),
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 9 ? "9+" : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _glassActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _grid(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
        children: [
          _btn("الكورسات", "assets/images/courses.png", () {
            _NavGuard.go(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoursesPage()),
                ));
          }),
          _btn("الدفع", "assets/images/payment.png", () {
            _NavGuard.go(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentPage()),
                ));
          }),
          _btn("المتصدرين", "assets/images/leaderboard.png", () {
            _NavGuard.go(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                ));
          }),
          if (isAdmin)
            _btn("Admin", "assets/images/admin.png", () {
              _NavGuard.go(() => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  ));
            }),
        ],
      ),
    );
  }

  Widget _btn(String t, String asset, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              asset,
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.image_not_supported, color: AppColors.gold.withValues(alpha: 0.7), size: 35),
            ),
            const SizedBox(height: 12),
            Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _hero(String userName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "أهلاً، $userName",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "بوابتك للاحتراف في المجال الطبي من الإسكندرية",
            style: TextStyle(color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _NavGuard.go(() => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursesPage()),
                    ));
              },
              child: const Text(
                "ابدأ الآن",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vipCard(bool isAdmin, bool subscribed, bool isVIP) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.star : (isVIP ? Icons.workspace_premium : (subscribed ? Icons.verified : Icons.lock_outline)),
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            isAdmin ? "حساب الإدارة" : (isVIP ? "عضوية VIP خاصة" : (subscribed ? "عضوية ذهبية VIP" : "باقة مجانية")),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(bool isAdmin, bool subscribed, bool isVIP, int xp, int streak) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("XP", xp.toString(), Icons.bolt_rounded),
          _statItem(
            "الحالة",
            isAdmin ? "إدارة" : (isVIP ? "VIP" : (subscribed ? "ذهبي VIP" : "Free")),
            Icons.shield_outlined,
          ),
          _statItem("Streak", "$streak يوم", Icons.local_fire_department_rounded),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 22),
        const SizedBox(height: 8),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _subscribeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
        ),
        onPressed: () => _NavGuard.go(() => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentPage()),
            )),
        child: const Text(
          "اشترك الآن وافتح كافة الكورسات 🔥",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _continueWatching() {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.lastWatch)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

        final courseId = snapshot.data!.docs.first['courseId'];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseService.firestore
              .collection(AppConstants.courses)
              .doc(courseId)
              .get(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) return const SizedBox();
            final data = snap.data!.data() as Map<String, dynamic>;
            if (!_isVisibleCourse(data)) return const SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title("⏯ أكمل المشاهدة"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CourseCard(
                    id: courseId,
                    data: data,
                    doneLessons: 0,
                    hasAccess: true,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _recommended() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("⭐ مقترح لك"),
        SizedBox(
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection(AppConstants.courses)
                .orderBy("createdAt", descending: true)
                .limit(6)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _isVisibleCourse(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 5),
                    child: CourseCard(
                      id: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      doneLessons: 0,
                      hasAccess: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _courses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.courses)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        final courses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isVisibleCourse(data);
        }).toList();

        if (courses.isEmpty) {
          return const Center(
            child: Text(
              "🚫 لا يوجد كورسات حالياً",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 290,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => CourseCard(
            id: courses[index].id,
            data: courses[index].data() as Map<String, dynamic>,
            doneLessons: 0,
            hasAccess: true,
          ),
        );
      },
    );
  }

  Widget _skeleton() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(15),
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ],
      ),
    );
  }
}