import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'core/firebase_service.dart';

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

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
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
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      ProfileHeader(controller: controller),
                      const SizedBox(height: 16),

                      ProfileOverview(controller: controller),
                      const SizedBox(height: 16),

                      ProfileStats(
                        coursesCount: controller.enrolledCourses.length,
                        totalPaid:
                            _safeInt(controller.studentData?['totalPaid']),
                        remaining:
                            _safeInt(controller.studentData?['remaining']),
                        completion: controller.profileCompletion(),
                      ),
                      const SizedBox(height: 16),

                      ProfileCourses(controller: controller),
                      const SizedBox(height: 16),

                      ProfileAttendance(uid: user.uid),
                      const SizedBox(height: 16),

                      ProfileFinance(uid: user.uid),
                      const SizedBox(height: 16),

                      ProfileEdit(controller: controller),
                      const SizedBox(height: 16),

                      ProfileActions(controller: controller),
                      const SizedBox(height: 30),
                    ],
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