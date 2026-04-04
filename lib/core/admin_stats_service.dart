import 'firebase_service.dart';
import 'constants.dart';

class AdminStatsService {

  static Map<String, dynamic>? _cache;
  static DateTime? _lastFetch;
  static bool _loading = false;

  static Future<Map<String, dynamic>> getStats() async {
    try {

      if (_cache != null &&
          _lastFetch != null &&
          DateTime.now().difference(_lastFetch!).inSeconds < 30) {
        return _cache!;
      }

      if (_loading && _cache != null) {
        return _cache!;
      }

      _loading = true;

      final usersSnap = await FirebaseService.firestore
          .collection(AppConstants.users)
          .get();

      final coursesSnap = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .get();

      final paymentsSnap = await FirebaseService.firestore
          .collection(AppConstants.payments)
          .get();

      final analyticsSnap = await FirebaseService.firestore
          .collection("analytics_events")
          .get();

      Map<String, String> userNames = {};
      for (var u in usersSnap.docs) {
        var data = u.data();
        userNames[u.id] = (data['name'] ?? data['email'] ?? "User").toString();
      }

      Map<String, String> courseNames = {};
      for (var c in coursesSnap.docs) {
        var data = c.data();
        courseNames[c.id] = (data['title'] ?? "Course").toString();
      }

      int subscribed = 0;

      for (var u in usersSnap.docs) {
        var data = u.data();

        if (data['subscriptionEnd'] != null) {
          DateTime end =
              DateTime.tryParse(data['subscriptionEnd'].toString()) ??
                  DateTime.now();

          if (end.isAfter(DateTime.now())) {
            subscribed++;
          }
        }
      }

      int totalRevenue = 0;
      int monthlyRevenue = 0;
      int yearlyRevenue = 0;
      int pending = 0;

      for (var p in paymentsSnap.docs) {
        var data = p.data();

        int price = (data['paidAmount'] ?? data['price'] ?? 0);

        if (data['status'] == "pending") {
          pending++;
        }

        if (data['status'] == "approved") {
          totalRevenue += price;

          if (data['plan'] == AppConstants.planMonthly) {
            monthlyRevenue += price;
          }

          if (data['plan'] == AppConstants.planYearly) {
            yearlyRevenue += price;
          }
        }
      }

      Map<String, int> courseMap = {};
      Map<String, int> userMap = {};
      int activeUsers = 0;

      final now = DateTime.now();

      for (var e in analyticsSnap.docs) {
        var data = e.data();

        final type = (data['type'] ?? "").toString();
        final userId = (data['userId'] ?? "").toString();
        final courseId = (data['courseId'] ?? "").toString();
        final time = data['timestamp'];

        if (time != null) {
          final t = time.toDate();
          if (now.difference(t).inMinutes < 5) {
            activeUsers++;
          }
        }

        if (userId.isNotEmpty) {
          userMap[userId] = (userMap[userId] ?? 0) + 1;
        }

        if ((type == "course_view" || type == "open_course" || type == "view") && courseId.isNotEmpty) {
          courseMap[courseId] =
              (courseMap[courseId] ?? 0) + 1;
        }
      }

      List<MapEntry<String, int>> topCourses =
          courseMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      List<MapEntry<String, int>> topUsers =
          userMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      topCourses = topCourses.take(5).toList();
      topUsers = topUsers.take(5).toList();

      List<MapEntry<String, int>> namedTopCourses = topCourses.map((e) {
        return MapEntry(courseNames[e.key] ?? e.key, e.value);
      }).toList();

      List<MapEntry<String, int>> namedTopUsers = topUsers.map((e) {
        return MapEntry(userNames[e.key] ?? e.key, e.value);
      }).toList();

      double conversion =
          usersSnap.docs.isEmpty
              ? 0
              : (subscribed / usersSnap.docs.length);

      final result = {
        "users": usersSnap.docs.length,
        "subscribed": subscribed,
        "courses": coursesSnap.docs.length,
        "revenue": totalRevenue,
        "monthly": monthlyRevenue,
        "yearly": yearlyRevenue,
        "pending": pending,
        "payments": paymentsSnap.docs.length,
        "conversion": (conversion * 100).toInt(),
        "activeUsers": activeUsers,
        "topCourses": namedTopCourses,
        "topUsers": namedTopUsers,
      };

      _cache = result;
      _lastFetch = DateTime.now();

      return result;

    } catch (e) {
      print("🔥 ADMIN ERROR: $e");

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
            "activeUsers": 0,
            "topCourses": [],
            "topUsers": [],
          };

    } finally {
      _loading = false;
    }
  }
}