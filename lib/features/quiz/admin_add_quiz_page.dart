import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class AddQuizPage extends StatefulWidget {
  final String lessonId;

  const AddQuizPage({super.key, required this.lessonId});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {

  final List<Map<String, dynamic>> questions = [];

  final List<TextEditingController> questionControllers = [];
  final List<List<TextEditingController>> optionControllers = [];

  bool saving = false;
  bool loading = true;
  String? quizId;

  final ScrollController scrollController = ScrollController();

  String courseId = "";

  @override
  void initState() {
    super.initState();
    loadExistingQuiz();
  }

  @override
  void dispose() {
    scrollController.dispose();

    for (var c in questionControllers) {
      c.dispose();
    }
    for (var list in optionControllers) {
      for (var c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> loadExistingQuiz() async {
    try {

      final lessonDoc = await FirebaseService.firestore
          .collectionGroup(AppConstants.lessons)
          .where(FieldPath.documentId, isEqualTo: widget.lessonId)
          .limit(1)
          .get();

      if (lessonDoc.docs.isNotEmpty) {
        courseId = lessonDoc.docs.first.reference.parent.parent?.id ?? "";
      }

      final snap = await FirebaseService.firestore
          .collection(AppConstants.quizzes)
          .where("lessonId", isEqualTo: widget.lessonId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;

        quizId = doc.id;

        final raw = doc.data()['questions'];

        final loaded = raw is List
            ? List<Map<String, dynamic>>.from(raw)
            : [];

        for (var q in loaded) {
          _addLoadedQuestion(q);
        }

        _show("⚡ تم تحميل الكويز القديم");
      }
    } catch (e) {
      debugPrint("Load Quiz Error: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  void _addLoadedQuestion(Map<String, dynamic> q) {
    final opts = (q['options'] is List)
        ? List.from(q['options'])
        : ["", "", "", ""];

    questions.add({
      "question": q['question'] ?? "",
      "options": opts,
      "correctIndex": q['correctIndex'] ?? 0,
    });

    questionControllers.add(
      TextEditingController(text: q['question'] ?? ""),
    );

    optionControllers.add(
      List.generate(4, (i) {
        return TextEditingController(
          text: i < opts.length ? opts[i].toString() : "",
        );
      }),
    );
  }

  void addQuestion() {
    setState(() {
      questions.add({
        "question": "",
        "options": ["", "", "", ""],
        "correctIndex": 0,
      });

      questionControllers.add(TextEditingController());

      optionControllers.add(
        List.generate(4, (_) => TextEditingController()),
      );
    });
  }

  void duplicateQuestion(int index) {
    final q = questions[index];

    setState(() {
      questions.insert(index + 1, Map<String, dynamic>.from(q));

      questionControllers.insert(
        index + 1,
        TextEditingController(text: questionControllers[index].text),
      );

      optionControllers.insert(
        index + 1,
        optionControllers[index]
            .map((c) => TextEditingController(text: c.text))
            .toList(),
      );
    });
  }

  bool validate() {
    for (int i = 0; i < questions.length; i++) {

      if (questionControllers[i].text.trim().isEmpty) {
        _show("❌ السؤال رقم ${i + 1} فاضي");
        return false;
      }

      for (var c in optionControllers[i]) {
        if (c.text.trim().isEmpty) {
          _show("❌ في اختيار فاضي في السؤال ${i + 1}");
          return false;
        }
      }
    }

    return true;
  }

  Future<void> saveQuiz() async {

    if (questions.isEmpty) {
      _show("❌ لازم تضيف سؤال واحد على الأقل");
      return;
    }

    if (!validate()) return;

    if (saving) return;

    setState(() => saving = true);

    try {

      List<Map<String, dynamic>> finalQuestions = [];

      for (int i = 0; i < questions.length; i++) {
        finalQuestions.add({
          "question": questionControllers[i].text.trim(),
          "options": optionControllers[i]
              .map((c) => c.text.trim())
              .toList(),
          "correctIndex": questions[i]['correctIndex'] ?? 0,
        });
      }

      final ref = quizId != null
          ? FirebaseService.firestore
              .collection(AppConstants.quizzes)
              .doc(quizId)
          : FirebaseService.firestore
              .collection(AppConstants.quizzes)
              .doc();

      await ref.set({
        "lessonId": widget.lessonId,
        "courseId": courseId.isEmpty ? widget.lessonId : courseId,
        "questions": finalQuestions,
        "isActive": true,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        _show("✅ تم حفظ الكويز بنجاح");
      }

    } catch (e) {
      debugPrint("Save Error: $e");
      _show("❌ حصل خطأ");
    }

    if (mounted) setState(() => saving = false);
  }

  Future<void> deleteQuestion(int index) async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("حذف السؤال؟",
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("حذف")),
        ],
      ),
    );

    if (ok == true && index < questions.length) {
      setState(() {
        questions.removeAt(index);

        questionControllers[index].dispose();
        questionControllers.removeAt(index);

        for (var c in optionControllers[index]) {
          c.dispose();
        }
        optionControllers.removeAt(index);
      });
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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
        title: const Text("🧪 إدارة Quiz",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: questions.length,
              onReorder: (oldIndex, newIndex) {

                if (newIndex > oldIndex) newIndex--;

                setState(() {
                  final q = questions.removeAt(oldIndex);
                  questions.insert(newIndex, q);

                  final qc = questionControllers.removeAt(oldIndex);
                  questionControllers.insert(newIndex, qc);

                  final oc = optionControllers.removeAt(oldIndex);
                  optionControllers.insert(newIndex, oc);
                });
              },
              itemBuilder: (context, index) {

                var q = questions[index];

                return Container(
                  key: ValueKey("question_$index"),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: AppColors.premiumCard.copyWith(
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Column(
                    children: [

                      TextField(
                        controller: questionControllers[index],
                        decoration:
                            const InputDecoration(hintText: "السؤال"),
                      ),

                      const SizedBox(height: 10),

                      ...List.generate(4, (i) {
                        return Row(
                          children: [

                            Radio<int>(
                              value: i,
                              groupValue: q['correctIndex'] ?? 0,
                              onChanged: (val) {
                                setState(() {
                                  q['correctIndex'] = val ?? 0;
                                });
                              },
                            ),

                            Expanded(
                              child: TextField(
                                controller: optionControllers[index][i],
                                decoration: InputDecoration(
                                    hintText: "اختيار ${i + 1}"),
                              ),
                            ),
                          ],
                        );
                      }),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            onPressed: () => duplicateQuestion(index),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteQuestion(index),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [

                ElevatedButton(
                  style: AppColors.goldButton,
                  onPressed: addQuestion,
                  child: const Text("➕ إضافة سؤال"),
                ),

                const SizedBox(height: 10),

                saving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: AppColors.goldButton,
                        onPressed: saveQuiz,
                        child: const Text("💾 حفظ الكويز"),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}