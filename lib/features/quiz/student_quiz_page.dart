// 🔥 IMPORTS FIRST
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';


/// 🔥🔥🔥 ULTRA QUIZ UI UPGRADE LAYER 🔥🔥🔥

Widget questionHeader(int index, int total) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("سؤال ${index + 1}/$total",
            style: const TextStyle(color: Colors.grey)),
        const Icon(Icons.quiz, color: Colors.amber, size: 18),
      ],
    ),
  );
}

Widget answerBox({
  required String text,
  required Color borderColor,
  required VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}

/// 🔥🔥🔥 END UI LAYER 🔥🔥🔥


/// 🔥🔥🔥 LOGIC LAYER 🔥🔥🔥

class QuizGuard {
  static final Map<String, bool> _running = {};

  static bool canStart(String lessonId) {
    if (_running[lessonId] == true) return false;
    _running[lessonId] = true;
    return true;
  }

  static void finish(String lessonId) {
    _running[lessonId] = false;
  }
}

class QuizXP {
  static final Set<String> _given = {};

  static Future<void> give(String lessonId, int score) async {
    try {
      if (_given.contains(lessonId)) return;

      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      int xp = score * 10;

      await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .update({
        "xp": FieldValue.increment(xp),
      });

      _given.add(lessonId);

    } catch (e) {
      debugPrint("XP Error: $e");
    }
  }
}

Future<void> safeNavigateToResults(
    BuildContext context, String lessonId) async {
  try {
    if (!context.mounted) return;

    Navigator.pushReplacementNamed(
      context,
      "/quizResults",
      arguments: lessonId,
    );
  } catch (e) {
    debugPrint("Nav Error: $e");
  }
}

/// 🔥🔥🔥 END LOGIC LAYER 🔥🔥🔥


class QuizPage extends StatefulWidget {
  final String lessonId;

  const QuizPage({super.key, required this.lessonId});

  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage>
    with WidgetsBindingObserver {

  List<Map<String, dynamic>> questions = [];
  Map<int, int> answers = {};

  bool loading = true;
  bool submitted = false;
  bool alreadySolved = false;

  int score = 0;
  int bestScore = 0;

  Timer? timer;
  int timeLeft = 300;

  bool navigating = false;

  @override
  void initState() {
    super.initState();

    if (!QuizGuard.canStart(widget.lessonId)) {
      Future.microtask(() => Navigator.pop(context));
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    loadQuiz();
    startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    saveAnswers();
    QuizGuard.finish(widget.lessonId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !submitted) {
      submitQuiz();
    }
  }

  /// ================= TIMER =================
  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (timeLeft <= 0) {
        t.cancel();
        if (!submitted) submitQuiz();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  /// ================= LOAD =================
  Future<void> loadQuiz() async {

    final user = FirebaseService.auth.currentUser;

    try {
      final snap = await FirebaseService.firestore
          .collection("quizzes")
          .where("lessonId", isEqualTo: widget.lessonId)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        questions = List<Map<String, dynamic>>.from(
            data['questions'] ?? []);
        questions.shuffle();
      }

      if (user != null) {
        final result = await FirebaseService.firestore
            .collection("quiz_results")
            .doc("${user.uid}${widget.lessonId}")
            .get();

        if (result.exists) {
          alreadySolved = true;
          bestScore = result.data()?['score'] ?? 0;
        }

        await restoreAnswers(user.uid);
      }

    } catch (e) {
      debugPrint("Quiz Load Error: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  /// ================= SAVE =================
  Future<void> saveAnswers() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection("quiz_temp")
          .doc("${user.uid}${widget.lessonId}")
          .set({
        "answers": answers,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> restoreAnswers(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection("quiz_temp")
          .doc("${uid}${widget.lessonId}")
          .get();

      if (doc.exists) {
        final data = doc.data()?['answers'];
        if (data != null) {
          answers = Map<int, int>.from(data);
        }
      }

    } catch (_) {}
  }

  /// ================= SUBMIT =================
  Future<void> submitQuiz() async {

    if (submitted || navigating) return;

    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i]['correctIndex']) {
        correct++;
      }
    }

    score = correct;

    if (!mounted) return;

    setState(() => submitted = true);
    timer?.cancel();

    final user = FirebaseService.auth.currentUser;

    if (user != null) {
      try {

        final ref = FirebaseService.firestore
            .collection("quiz_results")
            .doc("${user.uid}${widget.lessonId}");

        final doc = await ref.get();
        int previous = doc.data()?['score'] ?? 0;

        if (score > previous) {
          await ref.set({
            "userId": user.uid,
            "lessonId": widget.lessonId,
            "score": score,
            "total": questions.length,
            "updatedAt": FieldValue.serverTimestamp(),
          });

          await QuizXP.give(widget.lessonId, score);
        }

        await FirebaseService.firestore
            .collection("quiz_temp")
            .doc("${user.uid}${widget.lessonId}")
            .delete();

      } catch (e) {
        debugPrint("Submit Error: $e");
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      navigating = true;
      await safeNavigateToResults(context, widget.lessonId);
    });
  }

  /// ================= UI =================
  String formatTime() {
    int m = timeLeft ~/ 60;
    int s = timeLeft % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  double percent() =>
      questions.isEmpty ? 0 : answers.length / questions.length;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("🧪 Quiz",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.gold),
            )
          : questions.isEmpty
              ? const Center(
                  child: Text(
                    "🚫 لا يوجد كويز",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "⏱ ${formatTime()}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    LinearProgressIndicator(
                      value: percent(),
                      color: AppColors.gold,
                      backgroundColor: Colors.grey.shade800,
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {

                          var q = questions[index];
                          List options = q['options'] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: AppColors.premiumCard,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                questionHeader(index, questions.length),

                                Text(
                                  q['question'] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                ...List.generate(options.length, (i) {

                                  bool selected = answers[index] == i;
                                  bool correct = q['correctIndex'] == i;

                                  Color color = Colors.grey;

                                  if (submitted) {
                                    if (correct) color = Colors.green;
                                    else if (selected) color = Colors.red;
                                  } else if (selected) {
                                    color = AppColors.gold;
                                  }

                                  return answerBox(
                                    text: options[i].toString(),
                                    borderColor: color,
                                    onTap: submitted
                                        ? null
                                        : () async {
                                            setState(() {
                                              answers[index] = i;
                                            });
                                            await saveAnswers();
                                          },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton(
                        style: AppColors.goldButton,
                        onPressed: answers.length ==
                                questions.length
                            ? submitQuiz
                            : null,
                        child: const Text("📤 تسليم الإجابات"),
                      ),
                    ),
                  ],
                ),
    );
  }
}