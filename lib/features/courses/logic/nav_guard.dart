import 'package:flutter/material.dart';

class NavGuard {
  static bool navigating = false;

  static void go(VoidCallback action) {
    if (navigating) return;

    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("Navigation Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      navigating = false;
    });
  }
}