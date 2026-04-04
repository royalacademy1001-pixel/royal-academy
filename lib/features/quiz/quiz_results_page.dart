// 🔥 IMPORTS FIRST
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';


/// 🔥🔥🔥 RESULTS SUPER UPGRADE LAYER 🔥🔥🔥

class ResultsCache {
  static final Map<String, String> names = {};
}

String safeName(Map<String, String> cache, String id) {
  return cache[id] ?? ResultsCache.names[id] ?? "User";
}

class XPAnimator {
  static Stream<int> animate(int start, int end) async* {
    int current = start;
    while (current < end) {
      await Future.delayed(const Duration(milliseconds: 15));
      current++;
      yield current;
    }
  }
}

/// 🔥🔥🔥 END UPGRADE LAYER 🔥🔥🔥



// 🔥 QUIZ RESULTS PAGE (FINAL ULTRA)

class QuizResultsPage extends StatefulWidget {
  final String lessonId;

  const QuizResultsPage({super.key, required this.lessonId});

  @override
  State<QuizResultsPage> createState() => QuizResultsPageState();
}

class QuizResultsPageState extends State<QuizResultsPage> {

  bool loading = true;

  int myScore = 0;
  int bestScore = 0;
  int total = 0;
  int myRank = 0;
  int myXP = 0;

  int gainedXP = 0;

  List topUsers = [];
  Map<String, String> usersNames = {};

  int animatedXP = 0;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  /// ================= LOAD =================
  Future<void> loadResults() async {

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {

      final myDoc = await FirebaseService.firestore
          .collection("quiz_results")
          .doc("${user.uid}${widget.lessonId}")
          .get();

      if (myDoc.exists) {
        myScore = myDoc.data()?['score'] ?? 0;
        bestScore = myScore;
        total = myDoc.data()?['total'] ?? 0;

        gainedXP = myScore * 10;
      }

      final userDoc = await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .get();

      myXP = userDoc.data()?['xp'] ?? 0;

      /// 🔥 FIX START VALUE
      animatedXP = (myXP - gainedXP) < 0 ? 0 : myXP - gainedXP;

      _animateXP();

      final snap = await FirebaseService.firestore
          .collection("quiz_results")
          .where("lessonId", isEqualTo: widget.lessonId)
          .get();

      List all = snap.docs;

      all.sort((a, b) {
        int sa = a['score'] ?? 0;
        int sb = b['score'] ?? 0;
        return sb.compareTo(sa);
      });

      for (int i = 0; i < all.length; i++) {
        if (all[i].id == "${user.uid}${widget.lessonId}") {
          myRank = i + 1;
          break;
        }
      }

      topUsers = all.take(10).toList();

      List ids = topUsers.map((e) => e['userId']).toSet().toList();

      if (ids.isNotEmpty) {
        final usersSnap = await FirebaseService.firestore
            .collection("users")
            .where(FieldPath.documentId, whereIn: ids)
            .get();

        for (var u in usersSnap.docs) {
          final name = u.data()['name'] ?? "User";
          usersNames[u.id] = name;
          ResultsCache.names[u.id] = name;
        }
      }

    } catch (e) {
      debugPrint("Results Error: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  /// 🔥 XP ANIMATION
  void _animateXP() async {
    await for (var val in XPAnimator.animate(animatedXP, myXP)) {
      if (!mounted) return;
      setState(() => animatedXP = val);
    }
  }

  /// 🔥 PERFORMANCE
  String performance() {
    if (total == 0) return "";

    double p = myScore / total;

    if (p == 1) return "🔥 ممتاز";
    if (p >= 0.7) return "💪 جيد جدًا";
    if (p >= 0.5) return "🙂 مقبول";
    return "❌ ضعيف";
  }

  /// 🔥 MEDAL
  String medal(int index) {
    if (index == 0) return "🥇";
    if (index == 1) return "🥈";
    if (index == 2) return "🥉";
    return "#${index + 1}";
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("🏆 النتيجة",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            /// SCORE
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: AppColors.premiumCard,
              child: Column(
                children: [

                  const Text(
                    "🎯 نتيجتك",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "$myScore / $total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    performance(),
                    style: const TextStyle(color: Colors.amber),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "⭐ أفضل نتيجة: $bestScore",
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),

            /// XP
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [

                  const Icon(Icons.flash_on, color: Colors.amber),

                  const SizedBox(width: 10),

                  Text(
                    "XP: $animatedXP (+$gainedXP)",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// RANK
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(15),
              decoration: AppColors.premiumCard,
              child: Row(
                children: [

                  const Icon(Icons.emoji_events,
                      color: Colors.orange),

                  const SizedBox(width: 10),

                  Text(
                    "ترتيبك: #$myRank",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "🔥 أفضل 10 طلاب",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (topUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "🚫 لا يوجد نتائج",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topUsers.length,
                itemBuilder: (context, index) {

                  var d = topUsers[index];

                  int score = d['score'] ?? 0;
                  String userId = d['userId'] ?? "";

                  String name = safeName(usersNames, userId);

                  bool isMe = FirebaseService.auth.currentUser?.uid == userId;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: AppColors.premiumCard.copyWith(
                      border: isMe
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [

                        Text(
                          medal(index),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            isMe ? "👤 $name (أنت)" : name,
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                        ),

                        Text(
                          "$score",
                          style: const TextStyle(
                              color: Colors.green),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}