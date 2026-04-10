import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CourseTabs extends StatelessWidget {
  final TabController controller;

  const CourseTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.4),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.gold,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.gold,
        tabs: const [
          Tab(text: "الفيديوهات"),
          Tab(text: "PDF"),
          Tab(text: "الصوتيات"),
        ],
      ),
    );
  }
}