import 'package:flutter/material.dart';

Widget buildProgressBar(double value) {
  return Container(
    height: 4,
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(10),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: value.clamp(0, 1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}