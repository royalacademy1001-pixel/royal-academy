class CoursePermissions {
  static bool hasAccess({
    required Map<String, dynamic>? userData,
    required String courseId,
  }) {
    if (userData == null) return false;

    bool isAdmin = userData['isAdmin'] == true;
    bool isVIP = userData['isVIP'] == true;
    bool subscribed = userData['subscribed'] == true;
    bool blocked = userData['blocked'] == true;
    bool instructor = userData['instructorApproved'] == true;

    if (blocked) return false;

    if (isAdmin || isVIP || instructor) return true;

    if (subscribed) return true;

    List unlocked = userData['unlockedCourses'] ?? [];
    List enrolled = userData['enrolledCourses'] ?? [];

    return unlocked.contains(courseId) || enrolled.contains(courseId);
  }

  static bool canOpenLesson({
    required bool hasAccess,
    required Map<String, dynamic> lessonData,
    required bool isLoggedIn,
  }) {
    if (lessonData['isFree'] == true) return true;

    if (!isLoggedIn) return false;

    if (hasAccess) return true;

    return false;
  }
}