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
  final VoidCallback onLink;
  final VoidCallback onResult;

  final VoidCallback? onAttendance; // 🔥 NEW

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
    required this.onLink,
    required this.onResult,
    this.onAttendance, // 🔥 NEW
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    List enrolled = data['enrolledCourses'] ?? [];
    List unlocked = data['unlockedCourses'] ?? [];

    bool subscribed = data['subscribed'] ?? false;
    bool vip = data['isVIP'] ?? false;
    bool linked = data['linked'] == true || data['linkedByAdmin'] == true;
    bool blocked = data['blocked'] ?? false;

    String image = (data['image'] ?? "").toString();
    String name = (data['name'] ?? "Student").toString();
    String phone = (data['phone'] ?? "").toString();
    String email = (data['email'] ?? "").toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0E0E0E),
            const Color(0xFF1A1A1A),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        children: [

          /// 🔥 HEADER
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gold,
                backgroundImage:
                    image.isNotEmpty && image.startsWith("http")
                        ? NetworkImage(image)
                        : null,
                child: image.isEmpty || !image.startsWith("http")
                    ? const Icon(Icons.person, color: Colors.black)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email.isNotEmpty ? email : "User",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    Text(
                      phone.isNotEmpty ? phone : "لا يوجد رقم",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 5,
                      runSpacing: -5,
                      children: [
                        if (subscribed || vip)
                          badge("VIP", Colors.green),

                        if (linked)
                          badge("LINKED", Colors.blue),

                        if (blocked)
                          badge("BLOCKED", Colors.red),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      extraInfo ??
                          "📚 ${enrolled.length} | 🔓 ${unlocked.length}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blue),
                onPressed: onEdit,
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔥 ACTIONS GRID (2026 STYLE)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
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
                icon: blocked ? Icons.lock_open : Icons.block,
                color: Colors.red,
                onTap: () => onBlock(blocked),
              ),

              actionBtn(
                icon: Icons.link,
                color: Colors.blue,
                onTap: onLink,
              ),

              actionBtn(
                icon: Icons.bar_chart,
                color: Colors.purple,
                onTap: onResult,
              ),

              /// 🔥🔥🔥 NEW ATTENDANCE
              if (onAttendance != null)
                actionBtn(
                  icon: Icons.check_circle,
                  color: Colors.teal,
                  onTap: onAttendance!,
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}