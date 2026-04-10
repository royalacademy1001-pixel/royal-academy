import 'package:flutter/material.dart';

import '../../core/colors.dart';

class HomeStatsCard extends StatelessWidget {
  final bool isAdmin;
  final bool subscribed;
  final bool isVIP;
  final int userXP;
  final int streak;

  const HomeStatsCard({
    super.key,
    required this.isAdmin,
    required this.subscribed,
    required this.isVIP,
    required this.userXP,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final bool safeIsAdmin = isAdmin == true;
    final bool safeIsVIP = isVIP == true;
    final bool safeSubscribed = subscribed == true;
    final int safeXP = userXP;
    final int safeStreak = streak;

    final Color statusColor = safeIsAdmin
        ? Colors.orange
        : (safeIsVIP
            ? Colors.green
            : (safeSubscribed ? Colors.lightBlueAccent : Colors.white54));

    final String statusValue = safeIsAdmin
        ? "إدارة"
        : (safeIsVIP ? "VIP" : (safeSubscribed ? "مشترك" : "Free"));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF101010),
            Color(0xFF0D0D0D),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.gold.withOpacity(0.16)),
                ),
                child: const Text(
                  "ملخص سريع",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  label: "XP",
                  value: safeXP.toString(),
                  icon: Icons.bolt_rounded,
                  accent: Colors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statItem(
                  label: "الحالة",
                  value: statusValue,
                  icon: Icons.shield_outlined,
                  accent: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statItem(
                  label: "Streak",
                  value: "$safeStreak يوم",
                  icon: Icons.local_fire_department_rounded,
                  accent: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.16)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}