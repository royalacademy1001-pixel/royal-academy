// 🔥 IMPORTS FIRST
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase_service.dart';
import '../../core/constants.dart';


// 🔥🔥🔥 ADMIN DASHBOARD ULTRA UPGRADE LAYER 🔥🔥🔥

Future<T?> safeCall<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }
}

// 🔥🔥🔥 END UPGRADE LAYER 🔥🔥🔥


// 🔥 FINAL ADMIN STATS SERVICE

class AdminStatsService {

  static Map<String, dynamic>? _cache;
  static DateTime? _lastFetch;
  static bool _fetching = false;

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static Future<Map<String, dynamic>> getStats() async {

    try {

      if (_fetching && _cache != null) return _cache!;

      _fetching = true;

      final results = await Future.wait([
        safeCall(() => FirebaseService.firestore.collection(AppConstants.users).get()),
        safeCall(() => FirebaseService.firestore.collection(AppConstants.courses).get()),
        safeCall(() => FirebaseService.firestore.collection(AppConstants.payments).get()),
        safeCall(() => FirebaseService.firestore.collection("analytics_events").get()),
      ]);

      final usersSnap = results[0] as QuerySnapshot?;
      final coursesSnap = results[1] as QuerySnapshot?;
      final paymentsSnap = results[2] as QuerySnapshot?;
      final analyticsSnap = results[3] as QuerySnapshot?;

      if (usersSnap == null ||
          coursesSnap == null ||
          paymentsSnap == null) {
        throw Exception("Fetch Failed");
      }

      int subscribed = 0;
      int instructorRequests = 0;
      int newUsersToday = 0;

      final now = DateTime.now();

      for (var u in usersSnap.docs) {

        final data = u.data() as Map<String, dynamic>;

        if (data['subscribed'] == true) {
          subscribed++;
        } else {
          final endDate = data['subscriptionEnd'];
          if (endDate != null) {
            final end = DateTime.tryParse(endDate.toString());
            if (end != null && end.isAfter(now)) {
              subscribed++;
            }
          }
        }

        if (data['instructorRequest'] == true &&
            data['instructorApproved'] != true) {
          instructorRequests++;
        }

        final created = data['createdAt'];
        if (created is Timestamp) {
          final d = created.toDate();
          if (d.year == now.year &&
              d.month == now.month &&
              d.day == now.day) {
            newUsersToday++;
          }
        }
      }

      int totalRevenue = 0;
      int monthly = 0;
      int yearly = 0;
      int pending = 0;
      int earningsToday = 0;

      Map<String, int> courseRevenue = {};
      Map<String, int> courseViews = {};
      Map<String, int> userActivity = {};

      int activeUsers = 0;

      for (var p in paymentsSnap.docs) {

        final data = p.data() as Map<String, dynamic>;

        final paid = _toInt(data['paid']) == 0
            ? _toInt(data['price'])
            : _toInt(data['paid']);

        final status = (data['status'] ?? "").toString();

        if (status == "pending") pending++;

        if (status == "approved") {

          totalRevenue += paid;

          if (data['plan'] == AppConstants.planMonthly) {
            monthly += paid;
          }

          if (data['plan'] == AppConstants.planYearly) {
            yearly += paid;
          }

          final created = data['createdAt'];
          if (created is Timestamp) {
            final d = created.toDate();
            if (d.year == now.year &&
                d.month == now.month &&
                d.day == now.day) {
              earningsToday += paid;
            }
          }

          final courseId = (data['courseId'] ?? "").toString();
          if (courseId.isNotEmpty) {
            courseRevenue[courseId] =
                (courseRevenue[courseId] ?? 0) + paid;
          }
        }
      }

      if (analyticsSnap != null) {
        for (var e in analyticsSnap.docs) {
          final data = e.data() as Map<String, dynamic>;

          final type = (data['type'] ?? "").toString();
          final userId = (data['userId'] ?? "").toString();
          final courseId = (data['courseId'] ?? "").toString();
          final time = (data['timestamp'] as Timestamp?)?.toDate();

          if (time != null &&
              now.difference(time).inMinutes < 5) {
            activeUsers++;
          }

          if (userId.isNotEmpty) {
            userActivity[userId] =
                (userActivity[userId] ?? 0) + 1;
          }

          if ((type == "course_view" || type == "open_course" || type == "view") && courseId.isNotEmpty) {
            courseViews[courseId] =
                (courseViews[courseId] ?? 0) + 1;
          }
        }
      }

      if (courseViews.isEmpty && analyticsSnap != null) {
        for (var e in analyticsSnap.docs) {
          final data = e.data() as Map<String, dynamic>;
          final courseId = (data['courseId'] ?? "").toString();
          if (courseId.isNotEmpty) {
            courseViews[courseId] =
                (courseViews[courseId] ?? 0) + 1;
          }
        }
      }

      if (userActivity.isEmpty && analyticsSnap != null) {
        for (var e in analyticsSnap.docs) {
          final data = e.data() as Map<String, dynamic>;
          final userId = (data['userId'] ?? "").toString();
          if (userId.isNotEmpty) {
            userActivity[userId] =
                (userActivity[userId] ?? 0) + 1;
          }
        }
      }

      List<MapEntry<String, int>> topCourses =
          courseViews.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      List<MapEntry<String, int>> topUsers =
          userActivity.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      topCourses = topCourses.take(5).toList();
      topUsers = topUsers.take(5).toList();

      String topCourse = "";
      int topValue = 0;

      courseRevenue.forEach((k, v) {
        if (v > topValue) {
          topValue = v;
          topCourse = k;
        }
      });

      final usersCount = usersSnap.docs.length;

      final conversion = usersCount == 0
          ? 0
          : ((subscribed / usersCount) * 100).clamp(0, 100).toInt();

      int usersGrowth = newUsersToday;
      int revenueGrowth = earningsToday;

      final result = {
        "users": usersCount,
        "subscribed": subscribed,
        "courses": coursesSnap.docs.length,
        "revenue": totalRevenue,
        "monthly": monthly,
        "yearly": yearly,
        "pending": pending,
        "payments": paymentsSnap.docs.length,
        "conversion": conversion,
        "instructorRequests": instructorRequests,
        "newUsersToday": newUsersToday,
        "earningsToday": earningsToday,
        "topCourse": topCourse,
        "topCourseRevenue": topValue,
        "usersGrowth": usersGrowth,
        "revenueGrowth": revenueGrowth,
        "activeUsers": activeUsers,
        "topCourses": topCourses,
        "topUsers": topUsers,
      };

      _cache = result;
      _lastFetch = DateTime.now();

      return result;

    } catch (e) {

      return _cache ??
          {
            "users": 0,
            "subscribed": 0,
            "courses": 0,
            "revenue": 0,
            "monthly": 0,
            "yearly": 0,
            "pending": 0,
            "payments": 0,
            "conversion": 0,
            "instructorRequests": 0,
            "newUsersToday": 0,
            "earningsToday": 0,
            "topCourse": "",
            "topCourseRevenue": 0,
            "usersGrowth": 0,
            "revenueGrowth": 0,
            "activeUsers": 0,
            "topCourses": [],
            "topUsers": [],
          };

    } finally {
      _fetching = false;
    }
  }

  static void clearCache() {
    _cache = null;
    _lastFetch = null;
  }
}