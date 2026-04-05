// 🔥 FINAL PRO STUDENT ITEM (ULTRA UI)

import 'package:flutter/material.dart';
import '../../core/colors.dart';

class StudentItem extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  final VoidCallback onEnroll;
  final VoidCallback onUnlock;
  final VoidCallback onVip;
  final Function(bool) onBlock;
  final VoidCallback onEdit;

  final String? extraInfo;

  const StudentItem({
    super.key,
    required this.userId,
    required this.data,
    required this.onEnroll,
    required this.onUnlock,
    required this.onVip,
    required this.onBlock,
    required this.onEdit,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {

    List enrolled = data['enrolledCourses'] ?? [];
    List unlocked = data['unlockedCourses'] ?? [];

    bool subscribed = data['subscribed'] ?? false;
    bool blocked = data['blocked'] ?? false;

    String image = (data['image'] ?? "").toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        children: [

          /// 🔥 HEADER
          Row(
            children: [

              /// 👤 AVATAR
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gold,
                backgroundImage:
                    image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? const Icon(Icons.person, color: Colors.black)
                    : null,
              ),

              const SizedBox(width: 12),

              /// 📄 INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      data['email'] ?? "User",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      extraInfo ??
                          "📚 ${enrolled.length} | 🔓 ${unlocked.length}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [

                        if (subscribed)
                          badge("VIP", Colors.green),

                        if (blocked)
                          badge("BLOCKED", Colors.red),

                      ],
                    ),
                  ],
                ),
              ),

              /// ⚙ SETTINGS
              IconButton(
                icon: const Icon(Icons.settings,
                    color: Colors.blue),
                onPressed: onEdit,
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔥 ACTION BUTTONS (PRO STYLE)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              actionBtn(
                icon: Icons.add,
                color: Colors.green,
                onTap: onEnroll,
              ),

              actionBtn(
                icon: Icons.lock_open,
                color: Colors.orange,
                onTap: onUnlock,
              ),

              actionBtn(
                icon: Icons.star,
                color: Colors.amber,
                onTap: onVip,
              ),

              actionBtn(
                icon: blocked
                    ? Icons.lock_open
                    : Icons.block,
                color: Colors.red,
                onTap: () => onBlock(blocked),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}