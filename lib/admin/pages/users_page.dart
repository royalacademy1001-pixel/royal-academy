import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '/shared/widgets/loading_widget.dart';
import 'edit_student_page.dart';

part 'users_logic.dart';
part 'users_widgets.dart';
part 'users_actions.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<List<Map<String, dynamic>>>? _usersFuture;
  Future<List<Map<String, dynamic>>>? _coursesFuture;

  final Map<String, Future<bool>> _adminCache = {};

  String search = "";
  String filterMode = "all";
  String? selectedCourseId;
  String selectedCourseTitle = "";

  bool loadingAction = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = UsersLogic.loadUsers();
    _coursesFuture = UsersLogic.loadCourses();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final nextUsers = UsersLogic.loadUsers();
    final nextCourses = UsersLogic.loadCourses();

    if (mounted) {
      setState(() {
        _usersFuture = nextUsers;
        _coursesFuture = nextCourses;
        _adminCache.clear();
      });
    }

    await Future.wait([nextUsers, nextCourses]);
  }

  Future<void> _refreshUsers() async {
    final nextUsers = UsersLogic.loadUsers();

    if (mounted) {
      setState(() {
        _usersFuture = nextUsers;
      });
    }

    await nextUsers;
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> confirm(String text) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          TextButton(
            child: const Text("تأكيد"),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> runAction(Future<void> Function() action, String msg) async {
    if (loadingAction || !mounted) return;

    setState(() => loadingAction = true);

    try {
      await action();
      if (mounted) show(msg);
    } catch (e) {
      debugPrint("Users Action Error: $e");
      if (mounted) show("حصل خطأ ❌");
    } finally {
      if (mounted) {
        setState(() => loadingAction = false);
      } else {
        loadingAction = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaleFactor: 0.9),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "👥 Users Dashboard",
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () async {
                searchController.clear();
                setState(() {
                  search = "";
                  filterMode = "all";
                  selectedCourseId = null;
                  selectedCourseTitle = "";
                  _adminCache.clear();
                });
                await _refreshAll();
              },
              icon: const Icon(Icons.refresh, color: AppColors.gold),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: const SizedBox(),
                ),
              ),
            ),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnap) {
                if (authSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingWidget());
                }

                if (authSnap.hasError) {
                  return _errorView("❌ حدث خطأ أثناء قراءة حالة الدخول");
                }

                final user = authSnap.data;
                if (user == null) {
                  return _unauthorizedView();
                }

                final adminFuture = _adminCache.putIfAbsent(
                  user.uid,
                  () => UsersLogic.checkAdmin(user.uid),
                );

                return FutureBuilder<bool>(
                  future: adminFuture,
                  builder: (context, adminSnap) {
                    if (adminSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingWidget());
                    }

                    if (adminSnap.hasError) {
                      return _errorView("❌ حدث خطأ أثناء التحقق من الصلاحيات");
                    }

                    if (adminSnap.data != true) {
                      return _unauthorizedView();
                    }

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _usersFuture,
                      builder: (context, usersSnap) {
                        if (usersSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: LoadingWidget());
                        }

                        if (usersSnap.hasError) {
                          return _errorView("❌ حدث خطأ في تحميل بيانات المستخدمين");
                        }

                        final users = usersSnap.data ?? [];
                        return _buildContent(users, user.uid);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}