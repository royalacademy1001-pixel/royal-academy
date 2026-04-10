import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CenterHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CenterHeader({
    super.key,
    required this.userData,
  });

  String _safe(dynamic v, [String f = ""]) {
    final t = v?.toString().trim() ?? "";
    return t.isEmpty ? f : t;
  }

  bool _isAdmin(Map<String, dynamic> d) {
    final permissions = d['permissions'];
    final hasCenterPermission =
        permissions is Map && permissions['centerManagement'] == true;

    return d['isAdmin'] == true ||
        d['role'] == 'admin' ||
        hasCenterPermission;
  }

  bool _isVIP(Map<String, dynamic> d) {
    return d['isVIP'] == true || d['subscribed'] == true;
  }

  Color _roleColor(bool isAdmin, bool isVIP) {
    if (isAdmin) return Colors.redAccent;
    if (isVIP) return AppColors.gold;
    return Colors.grey;
  }

  String _roleText(bool isAdmin, bool isVIP) {
    if (isAdmin) return "ADMIN";
    if (isVIP) return "VIP";
    return "USER";
  }

  @override
  Widget build(BuildContext context) {
    final name = _safe(userData['name'], "Admin");
    final email = _safe(userData['email'], "No Email");
    final avatar = _safe(userData['image']);

    final isAdmin = _isAdmin(userData);
    final isVIP = _isVIP(userData);

    final roleColor = _roleColor(isAdmin, isVIP);
    final roleText = _roleText(isAdmin, isVIP);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.black,
            AppColors.black.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: avatar.isEmpty
                      ? Container(
                          color: Colors.black,
                          child: const Icon(Icons.person, color: Colors.white),
                        )
                      : Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: roleColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        roleText,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "متصل الآن",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings, color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}