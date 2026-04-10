import 'package:flutter/material.dart';

class AdminMenuItem {
  final String id;
  final String title;
  final Widget page;
  final IconData icon;

  const AdminMenuItem({
    required this.id,
    required this.title,
    required this.page,
    required this.icon,
  });
}