import 'package:flutter/material.dart';

class AdminSection extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}