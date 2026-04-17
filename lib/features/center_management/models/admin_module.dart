import 'package:flutter/material.dart';

class AdminModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  final String section;
  final bool requiresVIP;
  final bool requiresAdmin;
  final bool requiresInstructor;
  final int order;

  const AdminModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.section,
    this.requiresVIP = false,
    this.requiresAdmin = false,
    this.requiresInstructor = false,
    this.order = 0,
  });

  bool canAccess({
    required bool isAdmin,
    required bool isVIP,
    required bool isInstructor,
  }) {
    if (!isAdmin) return false;
    if (requiresAdmin && !isAdmin) return false;
    if (requiresVIP && !isVIP) return false;
    if (requiresInstructor && !isInstructor) return false;
    return true;
  }

  AdminModule copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    Widget? page,
    String? section,
    bool? requiresVIP,
    bool? requiresAdmin,
    bool? requiresInstructor,
    int? order,
  }) {
    return AdminModule(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      page: page ?? this.page,
      section: section ?? this.section,
      requiresVIP: requiresVIP ?? this.requiresVIP,
      requiresAdmin: requiresAdmin ?? this.requiresAdmin,
      requiresInstructor: requiresInstructor ?? this.requiresInstructor,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'section': section,
      'requiresVIP': requiresVIP,
      'requiresAdmin': requiresAdmin,
      'requiresInstructor': requiresInstructor,
      'order': order,
    };
  }

  factory AdminModule.fromMap(Map<String, dynamic> map, Widget page, IconData icon) {
    return AdminModule(
      id: map['id'] ?? "",
      title: map['title'] ?? "",
      subtitle: map['subtitle'] ?? "",
      icon: icon,
      page: page,
      section: map['section'] ?? "",
      requiresVIP: map['requiresVIP'] == true,
      requiresAdmin: map['requiresAdmin'] == true,
      requiresInstructor: map['requiresInstructor'] == true,
      order: map['order'] is int ? map['order'] : 0,
    );
  }
}