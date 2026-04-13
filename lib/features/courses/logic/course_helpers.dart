import 'package:royal_academy/core/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String fixImage(String url) {
  if (url.isEmpty) return "";
  return FirebaseService.fixImage(url);
}

bool isVisibleCourse(Map<String, dynamic> data, bool isAdminUser) {
  if (isAdminUser) return true;

  final approved = data['approved'] == true;
  final status = (data['status'] ?? "").toString().toLowerCase();

  return approved || status == "approved";
}

String safeText(dynamic value, [String fallback = ""]) {
  final text = value?.toString().trim() ?? "";
  return text.isEmpty ? fallback : text;
}

int safeInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? "") ?? fallback;
}

double safeDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? "") ?? fallback;
}

bool hasCourseAccess(Map<String, dynamic>? userData, String courseId) {
  if (userData == null) return false;

  bool isAdmin = userData['isAdmin'] == true;
  bool isVIP = userData['isVIP'] == true;
  bool subscribed = userData['subscribed'] == true;

  List unlocked = userData['unlockedCourses'] ?? [];
  List enrolled = userData['enrolledCourses'] ?? [];

  return isAdmin ||
      isVIP ||
      subscribed ||
      unlocked.contains(courseId) ||
      enrolled.contains(courseId);
}

bool matchSearch(Map<String, dynamic> data, String search) {
  if (search.isEmpty) return true;

  final s = search.toLowerCase().trim();

  final title = safeText(data['title']).toLowerCase();
  final description = safeText(data['description']).toLowerCase();
  final category = safeText(data['categoryName']).toLowerCase();

  final tags = (data['tags'] is List)
      ? (data['tags'] as List)
          .map((e) => e.toString().toLowerCase())
          .toList()
      : <String>[];

  return title.contains(s) ||
      description.contains(s) ||
      category.contains(s) ||
      tags.any((t) => t.contains(s));
}

bool matchAdvancedFilter(
  Map<String, dynamic> data, {
  required String level,
  required String price,
}) {
  final courseLevel = safeText(data['level']).toLowerCase();

  final isFree = data['isFree'] == true;

  final levelMatch =
      level == "All" || courseLevel == level.toLowerCase();

  final priceMatch = price == "All" ||
      (price == "free" && isFree) ||
      (price == "paid" && !isFree);

  return levelMatch && priceMatch;
}

List<QueryDocumentSnapshot> sortCourses(
  List<QueryDocumentSnapshot> list, {
  required String sort,
}) {
  list.sort((a, b) {
    final aRaw = a.data();
    final bRaw = b.data();

    final aData = aRaw is Map<String, dynamic> ? aRaw : <String, dynamic>{};
    final bData = bRaw is Map<String, dynamic> ? bRaw : <String, dynamic>{};

    if (sort == "popular") {
      int aViews = safeInt(aData['views']);
      int bViews = safeInt(bData['views']);
      return bViews.compareTo(aViews);
    }

    if (sort == "rating") {
      double aRate = safeDouble(aData['rating'], 0);
      double bRate = safeDouble(bData['rating'], 0);
      return bRate.compareTo(aRate);
    }

    if (sort == "new") {
      final aTime = aData['createdAt'];
      final bTime = bData['createdAt'];

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      try {
        return (bTime as dynamic).compareTo(aTime);
      } catch (_) {
        return 0;
      }
    }

    return 0;
  });

  return list;
}