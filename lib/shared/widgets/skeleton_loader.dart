import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  Widget box({double height = 15, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 220, color: Colors.grey.shade900),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              box(width: 200),
              box(),
              box(width: 150),
              const SizedBox(height: 20),
              ...List.generate(5, (_) => box(height: 60)),
            ],
          ),
        ),
      ],
    );
  }
}