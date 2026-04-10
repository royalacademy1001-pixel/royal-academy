import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';
import '../models/center_summary.dart';

class CenterService {
  static final FirebaseFirestore _db = FirebaseService.firestore;

  static CenterSummary? _cachedSummary;
  static DateTime? _lastFetch;

  static const Duration cacheDuration = Duration(seconds: 30);

  static Future<CenterSummary> getSummary({bool forceRefresh = false}) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedSummary != null &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < cacheDuration) {
      return _cachedSummary!;
    }

    try {
      final results = await Future.wait([
        _safeGet("courses"),
        _safeGet("users"),
        _safeGet("payments"),
        _safeGet("attendance_sessions"),
        _safeGet("analytics_events"),
      ]);

      final courseSnap = results[0];
      final userSnap = results[1];
      final paymentSnap = results[2];
      final sessionSnap = results[3];
      final analyticsSnap = results[4];

      int approvedPayments = 0;
      double revenue = 0;

      for (final doc in paymentSnap.docs) {
        final data = doc.data();
        final status = _safeString(data['status']).toLowerCase();

        if (status == "approved" ||
            status == "paid" ||
            status == "success") {
          approvedPayments++;
          revenue += _readMoney(data);
        }
      }

      final summary = CenterSummary(
        totalCourses: courseSnap.size,
        totalUsers: userSnap.size,
        totalPayments: paymentSnap.size,
        approvedPayments: approvedPayments,
        revenue: revenue,
        totalSessions: sessionSnap.size,
        totalEvents: analyticsSnap.size,
        lastUpdated: now,
      );

      _cachedSummary = summary;
      _lastFetch = now;

      return summary;
    } catch (_) {
      return _cachedSummary ?? CenterSummary.empty();
    }
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _safeGet(String collection) async {
    try {
      return await _db.collection(collection).get();
    } catch (_) {
      return await _db.collection(collection).limit(1).get();
    }
  }

  static double _readMoney(Map<String, dynamic> data) {
    final values = [
      data['paid'],
      data['amount'],
      data['price'],
      data['value'],
    ];

    for (final v in values) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  static String _safeString(dynamic value) {
    if (value == null) return "";
    return value.toString();
  }

  static Stream<CenterSummary> liveSummary() async* {
    while (true) {
      final summary = await getSummary(forceRefresh: true);
      yield summary;
      await Future.delayed(const Duration(seconds: 20));
    }
  }

  static void clearCache() {
    _cachedSummary = null;
    _lastFetch = null;
  }

  static Future<int> countCollection(String name) async {
    try {
      final snap = await _db.collection(name).count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 10}) async {
    try {
      final snap = await _db
          .collection("payments")
          .orderBy("createdAt", descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((e) => e.data()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTopStudents({int limit = 10}) async {
    try {
      final snap = await _db
          .collection("users")
          .orderBy("xp", descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((e) => e.data()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> systemHealth() async {
    try {
      final start = DateTime.now();

      await _db.collection("users").limit(1).get();

      final latency = DateTime.now().difference(start).inMilliseconds;

      return {
        "status": "ok",
        "latency": latency,
        "time": DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return {
        "status": "error",
        "latency": -1,
        "time": DateTime.now().toIso8601String(),
      };
    }
  }
}