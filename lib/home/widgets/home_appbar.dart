import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';

class HomeAppBar extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? notificationStream;
  final VoidCallback onNotificationsTap;

  const HomeAppBar({
    super.key,
    required this.notificationStream,
    required this.onNotificationsTap,
  });

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "صباح الخير ☀️";
    if (h < 18) return "مساء الخير 🌤";
    return "مساء الخير 🌙";
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 105,
      floating: true,
      pinned: true,
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        title: Text(
          greeting(),
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: notificationStream,
          builder: (context, snapshot) {
            final user = FirebaseService.auth.currentUser;
            int count = 0;

            if (snapshot.hasData && user != null) {
              count = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                return (data['userId'] == user.uid || data['type'] == "all") &&
                    !(data['seen'] ?? false);
              }).length;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: onNotificationsTap,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? "9+" : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}