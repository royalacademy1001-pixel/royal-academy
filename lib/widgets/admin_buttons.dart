import 'package:flutter/material.dart';
import '../core/colors.dart';

class AdminButtons extends StatelessWidget {
  final List<Map<String, dynamic>> pages;

  const AdminButtons({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: pages.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3, // تعديل النسبة ليكون الشكل عرضي وأشيك
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = pages[index];
        final String title = item['title'] ?? "";
        final IconData icon = _getIcon(title);

        return _buildAdminButton(context, title, icon, item['page']);
      },
    );
  }

  Widget _buildAdminButton(BuildContext context, String title, IconData icon, Widget page) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.01),
          ],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          splashColor: AppColors.gold.withOpacity(0.1),
          highlightColor: AppColors.gold.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // خلفية دائرية خفيفة للأيقونة
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.gold,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String title) {
    // تم إضافة وتطوير حالات الأيقونات بناءً على الملفات اللي بعتها في الـ AdminPage
    if (title.contains("كورسات")) return Icons.auto_stories_rounded;
    if (title.contains("تصنيفات")) return Icons.category_rounded;
    if (title.contains("إشعارات")) return Icons.notifications_active_rounded;
    if (title.contains("مدفوعات")) return Icons.account_balance_wallet_rounded;
    if (title.contains("المستخدمين")) return Icons.people_alt_rounded;
    if (title.contains("طلاب")) return Icons.local_library_rounded;
    if (title.contains("مدرس")) return Icons.person_add_alt_1_rounded;
    if (title.contains("Analytics")) return Icons.insights_rounded;
    if (title.contains("أخبار")) return Icons.newspaper_rounded;
    
    return Icons.grid_view_rounded;
  }
}