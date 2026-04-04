// 🔥 IMPORTS FIRST
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Firebase
import 'core/firebase_service.dart';
import 'core/constants.dart';

// 🔥 UI
import 'core/colors.dart';


/// 🔥🔥🔥 ULTRA LEADERBOARD UPGRADE LAYER 🔥🔥🔥

class LeaderboardCache {
  static Map<String, Map<String, dynamic>> usersCache = {};
  static bool initialized = false;
}

Widget repaintSafe(Widget child) {
  return RepaintBoundary(child: child);
}

/// 🔥🔥🔥 END UPGRADE LAYER 🔥🔥🔥


class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {

    var currentUser = FirebaseService.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "🏆 Royal Leaderboard",
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.black,
      ),

      body: repaintSafe(
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.firestore
              .collection(AppConstants.users)
              .orderBy("xp", descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, usersSnapshot) {

            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }

            if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "🚫 لا يوجد متسابقين حالياً",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            final usersDocs = usersSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: usersDocs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      buildTopThree(usersDocs, currentUser?.uid),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text("الترتيب العام", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Expanded(child: Divider(indent: 20, color: Colors.white10)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }

                int userIndex = index - 1;
                if (userIndex < 3) return const SizedBox.shrink();

                var userDoc = usersDocs[userIndex];
                var userData = userDoc.data();
                
                return buildUserTile(
                  userDoc.id,
                  userData['xp'] ?? 0,
                  index,
                  userData,
                  currentUser?.uid,
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// ================= LEVEL =================

  String getLevel(int xp) {
    if (xp < 100) return "Beginner";
    if (xp < 300) return "Intermediate";
    if (xp < 700) return "Advanced";
    return "Pro";
  }

  String getBadge(int xp) {
    if (xp < 100) return "🥉";
    if (xp < 300) return "🥈";
    if (xp < 700) return "🥇";
    return "👑";
  }

  String medal(int rank) {
    if (rank == 1) return "🥇";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "#$rank";
  }

  /// ================= TOP 3 =================

  Widget buildTopThree(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String? currentUserId) {
    int count = docs.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (count > 1)
            Expanded(child: buildTopUser(docs[1].data(), docs[1].id, 2, currentUserId)),
          
          if (count > 0)
            Expanded(child: buildTopUser(docs[0].data(), docs[0].id, 1, currentUserId, isMain: true)),

          if (count > 2)
            Expanded(child: buildTopUser(docs[2].data(), docs[2].id, 3, currentUserId)),
        ],
      ),
    );
  }

  Widget buildTopUser(Map<String, dynamic> data, String userId, int rank, String? currentUserId, {bool isMain = false}) {
    String name = data['name'] ?? "User";
    String image = data['image'] ?? "";
    int xp = data['xp'] ?? 0;
    bool isMe = userId == currentUserId;

    Color rankColor = rank == 1 ? AppColors.gold : rank == 2 ? Colors.grey : Colors.brown;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(getBadge(xp), style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: isMain ? 4 : 2),
                boxShadow: [
                  if (rank == 1) BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                ],
              ),
              child: CircleAvatar(
                radius: isMain ? 45 : 35,
                backgroundColor: AppColors.black,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: rankColor, borderRadius: BorderRadius.circular(10)),
              child: Text("$rank", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isMe ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: isMain ? 14 : 12)),
        Text("$xp XP", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(getLevel(xp), style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  /// ================= LIST =================

  Widget buildUserTile(String userId, int score, int rank, Map<String, dynamic> data, String? currentUserId) {
    String name = data['name'] ?? "User";
    String image = data['image'] ?? "";
    bool isMe = userId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? AppColors.gold.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMe ? AppColors.gold : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(medal(rank), style: TextStyle(color: rank <= 3 ? AppColors.gold : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.black,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
              ),
            ],
          ),
        ),
        title: Text(name, style: TextStyle(color: isMe ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(getLevel(score), style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("$score", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
            const Text("XP", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}