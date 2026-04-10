import 'package:flutter/material.dart';

Widget adminSafe(Widget child) {
  return RepaintBoundary(child: child);
}

class AdminTapGuard {
  static bool _locked = false;

  static bool canTap() {
    if (_locked) return false;
    _locked = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      _locked = false;
    });
    return true;
  }
}