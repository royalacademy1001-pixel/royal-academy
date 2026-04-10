class AccessGuard {
  static String roleOf(Map<String, dynamic>? data) {
    final rawRole = (data?['role'] ?? '').toString().trim().toLowerCase();
    if (rawRole.isNotEmpty) return rawRole;

    if (data?['isAdmin'] == true) return 'admin';
    if (data?['isVIP'] == true) return 'vip';
    if (data?['instructorApproved'] == true) return 'instructor';
    if (data?['subscribed'] == true) return 'subscribed';

    return 'user';
  }

  static bool isAdmin(Map<String, dynamic>? data) {
    final role = roleOf(data);
    return role == 'admin' || data?['isAdmin'] == true;
  }

  static bool isVIP(Map<String, dynamic>? data) {
    final role = roleOf(data);
    return role == 'vip' || data?['isVIP'] == true;
  }

  static bool isInstructor(Map<String, dynamic>? data) {
    final role = roleOf(data);
    return role == 'instructor' || data?['instructorApproved'] == true;
  }

  static bool isSubscribed(Map<String, dynamic>? data) {
    final role = roleOf(data);
    return role == 'subscribed' || data?['subscribed'] == true;
  }

  static bool isRegularUser(Map<String, dynamic>? data) {
    final role = roleOf(data);
    return role == 'user';
  }

  static bool hasPermission(
    Map<String, dynamic>? data,
    String permissionKey,
  ) {
    final permissions = data?['permissions'];

    if (permissions is Map<String, dynamic>) {
      return permissions[permissionKey] == true;
    }

    if (permissions is Map) {
      return permissions[permissionKey] == true;
    }

    return false;
  }

  static bool canOpenProgramDashboard(Map<String, dynamic>? data) {
    return data != null;
  }

  static bool canOpenAdminDashboard(Map<String, dynamic>? data) {
    return isAdmin(data);
  }

  static bool canOpenCenterManagement(Map<String, dynamic>? data) {
    return isAdmin(data) || hasPermission(data, 'centerManagement');
  }

  static bool canViewVipStudentsOnly(Map<String, dynamic>? data) {
    return isVIP(data);
  }

  static bool canAccessNavItem(
    Map<String, dynamic> item,
    Map<String, dynamic>? userData,
  ) {
    final roles = item['roles'];

    if (roles == null) return true;

    if (roles is List) {
      if (roles.contains('all')) return true;

      final currentRole = roleOf(userData);

      for (final role in roles) {
        if (role.toString().toLowerCase() == currentRole) {
          return true;
        }
      }
    }

    return false;
  }

  static bool isVipStudentRecord(Map<String, dynamic>? data) {
    return isVIP(data) && !isAdmin(data);
  }

  // ✅🔥 الحل النهائي للمشكلة هنا
  static bool isLinkedToAccount(Map<String, dynamic>? data) {
    if (data == null) return false;

    final linkedId = data['linkedUserId'];

    if (linkedId == null) return false;

    return linkedId.toString().trim().isNotEmpty;
  }

  static bool isNotLinkedToAccount(Map<String, dynamic>? data) {
    return !isLinkedToAccount(data);
  }
}