import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/permission_service.dart';

class HomeNavGuard {
  static bool navigating = false;

  static void go(VoidCallback action, {String? role, String? page}) {
    if (navigating) return;

    if (role != null && page != null) {
      final allowed = PermissionService.canAccess(
        role: role,
        page: page,
      );
      if (!allowed) return;
    }

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

  static Future<void> goAsync(Future<void> Function() action, {String? role, String? page}) async {
    if (navigating) return;

    if (role != null && page != null) {
      final allowed = PermissionService.canAccess(
        role: role,
        page: page,
      );
      if (!allowed) return;
    }

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