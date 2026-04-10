import 'package:flutter/material.dart';

Widget quizBadge(bool hasQuiz, bool solved) {
  if (!hasQuiz) return const SizedBox();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: solved ? Colors.green : Colors.orange,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      solved ? "✔ Quiz" : "Quiz",
      style: const TextStyle(fontSize: 10, color: Colors.white),
    ),
  );
}