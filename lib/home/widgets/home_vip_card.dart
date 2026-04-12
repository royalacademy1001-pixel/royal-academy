import 'package:flutter/material.dart';

import '../../core/colors.dart';

class HomeVipCard extends StatelessWidget {
  final bool isAdmin;
  final bool subscribed;
  final bool isVIP;

  const HomeVipCard({
    super.key,
    required this.isAdmin,
    required this.subscribed,
    required this.isVIP,
  });

  @override
  Widget build(BuildContext context) {
    final bool safeIsAdmin = isAdmin == true;
    final bool safeIsVIP = isVIP == true;
    final bool safeSubscribed = subscribed == true;

    final String title = safeIsAdmin
        ? "حساب الإدارة"
        : (safeIsVIP
            ? "عضوية VIP سنتر"
            : (safeSubscribed ? "عضوية اشتراك أونلاين" : "باقة مجانية"));

    final String subtitle = safeIsAdmin
        ? "صلاحية كاملة داخل المنصة"
        : (safeIsVIP
            ? "مميزات سنتر VIP"
            : (safeSubscribed ? "اشتراك فعّال ومفعل" : "ابدأ مجانًا الآن"));

    final String badge = safeIsAdmin
        ? "إدارة"
        : (safeIsVIP ? "VIP" : (safeSubscribed ? "مشترك" : "مجاني"));

    final Color accent = safeIsAdmin
        ? Colors.orange
        : (safeIsVIP
            ? Colors.green
            : (safeSubscribed ? Colors.lightBlueAccent : Colors.white54));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF222222),
            Color(0xFF141414),
            Color(0xFF101010),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(
              safeIsAdmin
                  ? Icons.star_rounded
                  : (safeIsVIP
                      ? Icons.workspace_premium_rounded
                      : (safeSubscribed
                          ? Icons.verified_rounded
                          : Icons.lock_outline_rounded)),
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}