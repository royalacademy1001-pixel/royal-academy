import 'package:flutter/material.dart';
import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../services/admin_dashboard_service.dart' as admin_service;
import '../services/admin_nav_sync_service.dart';

class AdminController {
  bool isAdmin = false;
  bool checkingAdmin = true;
  bool loadingRefresh = false;

  Future<Map<String, dynamic>> statsFuture = Future.value({});

  Future<void> init(List<Map<String, dynamic>> allAdminPages, VoidCallback refreshUI) async {
    await _initAdmin();
    await AdminNavSyncService.sync(allAdminPages);

    if (isAdmin) {
      admin_service.AdminStatsService.clearCache();
      statsFuture = admin_service.AdminStatsService.getStats();
    }

    checkingAdmin = false;
    refreshUI();
  }

  Future<void> _initAdmin() async {
    try {
      final currentUser = FirebaseService.auth.currentUser;

      if (currentUser == null) {
        isAdmin = false;
        return;
      }

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(currentUser.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        isAdmin = false;
        return;
      }

      final data = doc.data() ?? {};

      isAdmin = (data['isAdmin'] ?? false) == true ||
          (data['role'] ?? "").toString().trim().toLowerCase() == "admin";
    } catch (_) {
      isAdmin = false;
    }
  }

  Future<void> refresh(VoidCallback updateUI) async {
    if (loadingRefresh) return;

    loadingRefresh = true;
    updateUI();

    try {
      admin_service.AdminStatsService.clearCache();
      final data = await admin_service.AdminStatsService.getStats();
      statsFuture = Future.value(data);
    } catch (_) {}

    loadingRefresh = false;
    updateUI();
  }
}