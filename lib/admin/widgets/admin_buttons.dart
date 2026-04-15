import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import '../../core/permission_service.dart';

class AdminButtons extends StatefulWidget {
  final List<Map<String, dynamic>> pages;

  const AdminButtons({super.key, required this.pages});

  @override
  State<AdminButtons> createState() => _AdminButtonsState();
}

class _AdminButtonsState extends State<AdminButtons> {
  bool _ready = false;
  String _role = "guest";
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      await PermissionService.load();
      _userData = await FirebaseService.getUserData();
      _role = PermissionService.getRole(_userData);
    } catch (_) {
      _role = "guest";
      _userData = {};
    }

    if (!mounted) return;

    setState(() {
      _ready = true;
    });
  }

  String _permissionKeyForTitle(String title) {
    if (title.contains("إضافة كورس")) return "add_course";
    if (title.contains("إضافة محتوى")) return "add_lesson";
    if (title.contains("إضافة Quiz")) return "add_quiz";
    if (title.contains("إضافة خبر")) return "add_news";
    if (title.contains("إضافة طالب")) return "add_student";
    if (title.contains("إدارة الكورسات")) return "courses";
    if (title.contains("إدارة التصنيفات")) return "categories";
    if (title.contains("الإشعارات")) return "notifications";
    if (title.contains("المدفوعات")) return "payments";
    if (title.contains("المستخدمين")) return "users";
    if (title.contains("إدارة الطلاب")) return "students";
    if (title.contains("طلبات المدرسين")) return "instructor_requests";
    if (title.contains("Analytics")) return "analytics";
    if (title.contains("إدارة الأخبار")) return "news";
    if (title.contains("CRM")) return "students_crm";
    if (title.contains("QR")) return "qr";
    if (title.contains("البار")) return "admin_navigation";
    if (title.contains("الأسعار")) return "pricing";
    if (title.contains("الصلاحيات")) return "permissions";
    if (title.contains("Permissions")) return "permissions";
    if (title.contains("إدارة الصلاحيات")) return "permissions";
    return "";
  }

  bool _canShowItem(Map<String, dynamic> item) {
    if (!_ready) return true;

    final visible = item['visible'];
    if (visible is bool && visible == false) return false;

    final rawPermissionKey = item['permissionKey'];
    final String permissionKey = rawPermissionKey == null
        ? _permissionKeyForTitle((item['title'] ?? "").toString())
        : rawPermissionKey.toString().trim();

    if (permissionKey.isEmpty) return true;

    return PermissionService.canAccess(
      role: _role,
      page: permissionKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePages = widget.pages.where(_canShowItem).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 3
                    : 2;

        if (visiblePages.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          itemCount: visiblePages.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: width >= 900 ? 1.4 : 1.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = visiblePages[index];
            final String title = (item['title'] ?? "").toString();
            final IconData icon = _getIcon(title);
            final Widget page = item['page'] is Widget
                ? item['page'] as Widget
                : const SizedBox.shrink();

            return _buildAdminButton(context, title, icon, page);
          },
        );
      },
    );
  }

  Widget _buildAdminButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return _AnimatedAdminCard(
      title: title,
      icon: icon,
      onTap: () {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  IconData _getIcon(String title) {
    if (title.contains("كورسات")) return Icons.auto_stories_rounded;
    if (title.contains("تصنيفات")) return Icons.category_rounded;
    if (title.contains("إشعارات")) return Icons.notifications_active_rounded;
    if (title.contains("مدفوعات")) return Icons.account_balance_wallet_rounded;
    if (title.contains("المستخدمين")) return Icons.people_alt_rounded;
    if (title.contains("طالب")) return Icons.person_rounded;
    if (title.contains("طلاب")) return Icons.local_library_rounded;
    if (title.contains("مدرس")) return Icons.person_add_alt_1_rounded;
    if (title.contains("QR")) return Icons.qr_code_rounded;
    if (title.contains("Analytics")) return Icons.insights_rounded;
    if (title.contains("أخبار")) return Icons.newspaper_rounded;
    if (title.contains("صلاحيات")) return Icons.lock_outline_rounded;
    if (title.contains("Permissions")) return Icons.lock_outline_rounded;

    return Icons.grid_view_rounded;
  }
}

class _AnimatedAdminCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedAdminCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AnimatedAdminCard> createState() => _AnimatedAdminCardState();
}

class _AnimatedAdminCardState extends State<_AnimatedAdminCard> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => hovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          hovered = false;
          pressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!mounted) return;
          setState(() => pressed = true);
        },
        onTapUp: (_) {
          if (!mounted) return;
          setState(() => pressed = false);
        },
        onTapCancel: () {
          if (!mounted) return;
          setState(() => pressed = false);
        },
        onTap: () {
          try {
            widget.onTap();
          } catch (_) {}
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: pressed
              ? 0.92
              : hovered
                  ? 1.08
                  : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, hovered ? -6.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: hovered ? 0.12 : 0.05),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
              border: Border.all(
                color: hovered
                    ? AppColors.gold.withValues(alpha: 0.8)
                    : AppColors.gold.withValues(alpha: 0.15),
                width: hovered ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? AppColors.gold.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: hovered ? 28 : 10,
                  spreadRadius: hovered ? 2 : 0,
                  offset: Offset(0, hovered ? 14 : 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(
                        alpha: hovered ? 0.3 : 0.08,
                      ),
                      boxShadow: hovered
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.gold,
                      size: hovered ? 32 : 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: hovered ? AppColors.gold : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: hovered ? 14 : 12,
                    ),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}