import 'package:flutter/material.dart';
import '../../core/colors.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final bool loading;

  const AdminAppBar({
    super.key,
    required this.onRefresh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      automaticallyImplyLeading: false,
      title: const Text(
        "⚙ Royal Dashboard",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.8,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: "تحديث",
                    icon: const Icon(Icons.refresh, color: AppColors.gold),
                    onPressed: onRefresh,
                  ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          width: double.infinity,
          color: AppColors.gold.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}