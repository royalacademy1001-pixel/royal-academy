import 'dart:async';
import 'package:flutter/material.dart';

class HomeNavGuard {
  static bool navigating = false;

  static void go(VoidCallback action) {
    if (navigating) return;
    navigating = true;

    try {
      action();
    } catch (e) {
      debugPrint("🔥 Nav Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      navigating = false;
    });
  }

  static Future<void> goAsync(Future<void> Function() action) async {
    if (navigating) return;
    navigating = true;

    try {
      await action();
    } catch (e) {
      debugPrint("🔥 Nav Async Error: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      navigating = false;
    }
  }
}