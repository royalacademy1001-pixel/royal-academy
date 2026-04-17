import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'core/firebase_service.dart';
import 'core/permission_service.dart';

import 'features/profile/controller/student_profile_controller.dart';

import 'features/profile/widgets/profile_header.dart';
import 'features/profile/widgets/profile_overview.dart';
import 'features/profile/widgets/profile_stats.dart';
import 'features/profile/widgets/profile_courses.dart';
import 'features/profile/widgets/profile_finance.dart';
import 'features/profile/widgets/profile_attendance.dart';
import 'features/profile/widgets/profile_edit.dart';
import 'features/profile/widgets/profile_actions.dart';

import 'shared/widgets/loading_widget.dart';

import 'pages/student_qr_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late StudentProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = StudentProfileController();
    controller.loadData();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    await PermissionService.load();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseService.auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "0") ?? 0;
  }

  bool _canShowStudentQr() {
    return PermissionService.canAccess(
      role: controller.role,
      page: "qr",
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text(
            "يرجى تسجيل الدخول",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 380 ? 0.85 : screenWidth < 420 ? 0.92 : 1.0;
    final showInlineStats = false;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final showStudentQr = _canShowStudentQr();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              "👤 لوحة تحكم الطالب",
              style: TextStyle(color: AppColors.gold),
            ),
            backgroundColor: AppColors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: () async {
                  await controller.loadData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await controller.loadData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(12 * scale),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        ProfileHeader(controller: controller),
                        SizedBox(height: 14 * scale),
                        ProfileOverview(controller: controller),
                        SizedBox(height: 14 * scale),
                        if (showInlineStats)
                          ProfileStats(
                            coursesCount: controller.enrolledCourses.length,
                            totalPaid: _safeInt(controller.studentData?['totalPaid']),
                            remaining: _safeInt(controller.studentData?['remaining']),
                            completion: controller.profileCompletion(),
                          ),
                        if (showInlineStats) SizedBox(height: 14 * scale),
                        ProfileCourses(controller: controller),
                        SizedBox(height: 14 * scale),
                        ProfileAttendance(uid: user.uid),
                        SizedBox(height: 14 * scale),
                        ProfileFinance(uid: user.uid),
                        SizedBox(height: 14 * scale),
                        ProfileEdit(controller: controller),
                        SizedBox(height: 14 * scale),
                        if (showStudentQr)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 14 * scale),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                padding: EdgeInsets.all(12 * scale),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14 * scale),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StudentQRPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code, color: Colors.black),
                              label: const Text(
                                "📱 QR الخاص بي",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ProfileActions(controller: controller),
                        SizedBox(height: 24 * scale),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.loading)
                Container(
                  color: Colors.black54,
                  child: const LoadingWidget(),
                ),
            ],
          ),
        );
      },
    );
  }
}