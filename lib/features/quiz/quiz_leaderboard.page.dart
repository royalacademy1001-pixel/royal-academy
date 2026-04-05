// 🔥 QUIZ LEADERBOARD PAGE (PRO MAX++ ULTRA FINAL SAFE + UPGRADED)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:royal_academy/core/firebase_service.dart';
import 'package:royal_academy/core/colors.dart';

class QuizLeaderboardPage extends StatelessWidget {
  final String lessonId;

  const QuizLeaderboardPage({
    super.key,
    required this.lessonId,
  });

  /// 🔥 CACHE USERS
  static final Map<String, Map<String, dynamic>> _userCache = {};

  String getMedal(int index) {
    if (index == 0) return "🥇";
    if (index == 1) return "🥈";
    if (index == 2) return "🥉";
    return "#${index + 1}";
  }

  @override
  Widget build(BuildContext context) {

    final currentUser = FirebaseService.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("🏆 المتصدرين",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("quiz_results")
            .where("lessonId", isEqualTo: lessonId)
            .orderBy("score", descending: true)
            .limit(20)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.gold),
            );
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "🚫 لا يوجد بيانات",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              var data = docs[index].data() as Map<String, dynamic>;

              int score = data['score'] ?? 0;
              int total = data['total'] ?? 1;

              double percent = (score / total) * 100;

              String userId = data['userId'] ?? "";

              bool isMe = currentUser != null &&
                  currentUser.uid == userId;

              /// 🔥 USE CACHE FIRST
              if (_userCache.containsKey(userId)) {
                return _buildTile(
                  index,
                  _userCache[userId]!,
                  score,
                  total,
                  percent,
                  isMe,
                );
              }

              /// 🔥 FETCH + CACHE
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseService.firestore
                    .collection("users")
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {

                  if (!userSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  Map<String, dynamic> userData = {};

                  if (userSnap.data!.exists) {
                    userData = userSnap.data!.data()
                        as Map<String, dynamic>? ?? {};
                  }

                  /// 🔥 SAVE CACHE
                  _userCache[userId] = userData;

                  return _buildTile(
                    index,
                    userData,
                    score,
                    total,
                    percent,
                    isMe,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// ================= TILE =================
  Widget _buildTile(
      int index,
      Map<String, dynamic> userData,
      int score,
      int total,
      double percent,
      bool isMe,
      ) {

    String name = (userData['name'] ?? "User").toString();
    String image = (userData['image'] ?? "").toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),

      decoration: AppColors.premiumCard.copyWith(
        border: Border.all(
          color: isMe
              ? Colors.green
              : Colors.transparent,
          width: 1.5,
        ),
      ),

      child: Row(
        children: [

          /// 🏆 RANK
          Text(
            getMedal(index),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(width: 10),

          /// 👤 AVATAR
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.gold,
            backgroundImage:
            image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : "U",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),

          const SizedBox(width: 10),

          /// 🧑 NAME
          Expanded(
            child: Text(
              isMe ? "$name (أنت)" : name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// 📊 %
          Text(
            "${percent.toStringAsFixed(0)}%",
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 10),

          /// 🎯 SCORE
          Text(
            "$score / $total",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}