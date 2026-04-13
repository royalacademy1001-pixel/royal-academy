part of 'users_page.dart';

class UsersLogic {
  static String text(dynamic value) {
    return value == null ? "" : value.toString().trim();
  }

  static bool boolValue(dynamic value) {
    return value == true;
  }

  static int intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(text(value)) ?? 0;
  }

  static Map<String, dynamic> safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static Future<bool> checkAdmin(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(uid)
          .get();

      final data = safeMap(doc.data());
      final role = text(data['role']).toLowerCase();

      return boolValue(data['isAdmin']) || role == "admin";
    } catch (e) {
      debugPrint("Admin Check Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> loadUsers() async {
    try {
      final snap = await FirebaseService.firestore
          .collection(AppConstants.users)
          .get();

      final users = snap.docs.map((doc) {
        final data = safeMap(doc.data());
        data['_id'] = doc.id;
        return data;
      }).toList();

      users.sort((a, b) {
        final vipA = boolValue(a['isVIP']);
        final vipB = boolValue(b['isVIP']);
        if (vipA != vipB) return vipA ? -1 : 1;

        final blockedA = boolValue(a['blocked']);
        final blockedB = boolValue(b['blocked']);
        if (blockedA != blockedB) return blockedA ? 1 : -1;

        final nameA = text(a['name']).toLowerCase();
        final nameB = text(b['name']).toLowerCase();
        return nameA.compareTo(nameB);
      });

      return users;
    } catch (e) {
      debugPrint("Load Users Error: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadCourses() async {
    try {
      final snap = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .get();

      final courses = snap.docs.map((doc) {
        final data = safeMap(doc.data());
        data['_id'] = doc.id;
        return data;
      }).toList();

      courses.sort((a, b) {
        final titleA = text(a['title']).toLowerCase();
        final titleB = text(b['title']).toLowerCase();
        return titleA.compareTo(titleB);
      });

      return courses;
    } catch (e) {
      debugPrint("Load Courses Error: $e");
      return [];
    }
  }

  static bool isStudentUser(Map<String, dynamic> data) {
    final role = text(data['role']).toLowerCase();
    final isAdmin = boolValue(data['isAdmin']);
    final instructorApproved = boolValue(data['instructorApproved']);
    final instructorRequest = boolValue(data['instructorRequest']);

    return !isAdmin &&
        role != "admin" &&
        role != "instructor" &&
        !instructorApproved &&
        !instructorRequest;
  }

  static bool isVip(Map<String, dynamic> data) {
    return boolValue(data['isVIP']);
  }

  static bool isBlocked(Map<String, dynamic> data) {
    return boolValue(data['blocked']);
  }

  static bool isLinked(Map<String, dynamic> data) {
    return text(data['studentId']).isNotEmpty;
  }

  static bool isSubscribed(Map<String, dynamic> data) {
    return boolValue(data['subscribed']);
  }

  static bool isAdminUser(Map<String, dynamic> data) {
    final role = text(data['role']).toLowerCase();
    return boolValue(data['isAdmin']) || role == "admin";
  }

  static bool isInstructor(Map<String, dynamic> data) {
    return boolValue(data['instructorApproved']) ||
        text(data['role']).toLowerCase() == "instructor";
  }

  static bool hasPendingInstructorRequest(Map<String, dynamic> data) {
    return boolValue(data['instructorRequest']) &&
        !boolValue(data['instructorApproved']);
  }

  static String courseTitleById(
      List<Map<String, dynamic>> courses, String? id) {
    if (id == null || id.isEmpty) return "";
    for (final course in courses) {
      if (text(course['_id']) == id) {
        final title = text(course['title']);
        return title.isEmpty ? id : title;
      }
    }
    return "";
  }

  static bool matchesFilter(
      Map<String, dynamic> data, String filterMode) {
    final vip = isVip(data);
    final blocked = isBlocked(data);
    final linked = isLinked(data);
    final subscribed = isSubscribed(data);
    final isAdmin = isAdminUser(data);
    final instructor = isInstructor(data);
    final request = hasPendingInstructorRequest(data);

    switch (filterMode) {
      case "vip":
        return vip;
      case "all":
        return true;
      case "linked":
        return linked;
      case "blocked":
        return blocked;
      case "unlinked":
        return !linked;
      case "subscribed":
        return subscribed;
      case "admins":
        return isAdmin;
      case "instructors":
        return instructor;
      case "requests":
        return request;
      case "students":
        return isStudentUser(data);
      default:
        return vip;
    }
  }

  static List<Map<String, dynamic>> applyFilters(
    List<Map<String, dynamic>> users,
    String search,
    String filterMode,
  ) {
    final q = search.trim().toLowerCase();

    final filtered = users.where((u) {
      final name = text(u['name']).toLowerCase();
      final email = text(u['email']).toLowerCase();
      final phone = text(u['phone']).toLowerCase();
      final studentId = text(u['studentId']).toLowerCase();
      final role = text(u['role']).toLowerCase();

      final matchesSearch = q.isEmpty ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          studentId.contains(q) ||
          role.contains(q);

      return matchesSearch && matchesFilter(u, filterMode);
    }).toList();

    filtered.sort((a, b) {
      final vipA = isVip(a);
      final vipB = isVip(b);
      if (vipA != vipB) return vipA ? -1 : 1;

      final blockedA = isBlocked(a);
      final blockedB = isBlocked(b);
      if (blockedA != blockedB) return blockedA ? 1 : -1;

      final nameA = text(a['name']).toLowerCase();
      final nameB = text(b['name']).toLowerCase();
      return nameA.compareTo(nameB);
    });

    return filtered;
  }
}