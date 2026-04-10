import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String text;

  const EmptyWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}