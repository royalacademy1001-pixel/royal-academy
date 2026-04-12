import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CenterHeader extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CenterHeader({
    super.key,
    required this.userData,
  });

  @override
  State<CenterHeader> createState() => _CenterHeaderState();
}

class _CenterHeaderState extends State<CenterHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

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
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _safe(widget.userData['name'], "Admin");
    final email = _safe(widget.userData['email'], "No Email");
    final avatar = _safe(widget.userData['image']);

    final isAdmin = _isAdmin(widget.userData);
    final isVIP = _isVIP(widget.userData);

    final roleColor = _roleColor(isAdmin, isVIP);
    final roleText = _roleText(isAdmin, isVIP);

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
            border: Border.all(
                color: AppColors.gold.withOpacity(0.4 + _glow.value * 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.12 + _glow.value * 0.2),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.gold
                              .withOpacity(0.4 + _glow.value * 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(_glow.value),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: avatar.isEmpty
                          ? Container(
                              color: Colors.black,
                              child: const Icon(Icons.person,
                                  color: Colors.white),
                            )
                          : Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black,
                                child: const Icon(Icons.person,
                                    color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(_glow.value),
                            blurRadius: 10,
                          )
                        ],
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: roleColor.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    roleColor.withOpacity(_glow.value * 0.5),
                                blurRadius: 12,
                              )
                            ],
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

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.gold
                          .withOpacity(0.3 + _glow.value * 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(_glow.value * 0.6),
                      blurRadius: 14,
                    )
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings, color: AppColors.gold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}