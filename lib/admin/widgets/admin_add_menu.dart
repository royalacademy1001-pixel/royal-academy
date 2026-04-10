import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../admin/add_course_page.dart';
import '../../admin/add_lesson_page.dart';
import '../../admin/add_news_page.dart';
import '../../features/quiz/admin_add_quiz_page.dart';

class AdminAddMenu {

  static bool openingMenu = false;

  static void open({
    required BuildContext context,
    required Future<void> Function() refresh,
    required Future<String?> Function() pickLesson,
  }) {

    if (openingMenu) return;

    openingMenu = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "🚀 إضافة جديدة",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 25),

                _item(
                  icon: Icons.menu_book,
                  color: AppColors.gold,
                  title: "إضافة كورس",
                  subtitle: "إنشاء كورس تدريبي جديد",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!context.mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCoursePage()),
                    );

                    if (!context.mounted) return;

                    await refresh();
                  },
                ),

                _item(
                  icon: Icons.play_circle,
                  color: Colors.green,
                  title: "إضافة محتوى",
                  subtitle: "رفع فيديو أو درس جديد",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!context.mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddLessonPage()),
                    );

                    if (!context.mounted) return;

                    await refresh();
                  },
                ),

                _item(
                  icon: Icons.quiz,
                  color: Colors.orange,
                  title: "إضافة Quiz",
                  subtitle: "إضافة اختبار لتقييم الطلاب",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    final lessonId = await pickLesson();

                    if (!context.mounted) return;

                    if (lessonId == null || lessonId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ لم يتم اختيار درس")),
                      );
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuizPage(lessonId: lessonId),
                      ),
                    );

                    if (!context.mounted) return;

                    await refresh();
                  },
                ),

                _item(
                  icon: Icons.campaign,
                  color: Colors.blue,
                  title: "إضافة خبر",
                  subtitle: "نشر إعلان هام للأكاديمية",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!context.mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddNewsPage()),
                    );

                    if (!context.mounted) return;

                    await refresh();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      openingMenu = false;
    });
  }

  static Widget _item({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }
}