import 'package:flutter/material.dart';
import 'colors.dart';

void showSnack(BuildContext context, String text,
    {Color color = Colors.green}) {

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.black,
      content: Text(
        text,
        style: TextStyle(color: color),
      ),
    ),
  );
}