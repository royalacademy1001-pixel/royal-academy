import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../widgets/custom_textfield.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {

  final searchController = TextEditingController();

  String search = "";
  String? selectedCourseId;

  bool loadingAction = false;

  late Stream<QuerySnapshot> usersStream;

  final ScrollController _scrollController = ScrollController();
  int limit = 20;

  @override
  void initState() {
    super.initState();

    usersStream = FirebaseFirestore.instance
        .collection('users')
        .limit(limit)
        .snapshots();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        setState(() {
          limit += 20;
          usersStream = FirebaseFirestore.instance
              .collection('users')
              .limit(limit)
              .snapshots();
        });
      }
    });
  }

  Future runAction(Future Function() action, String msg) async {
    if (loadingAction) return;

    setState(() => loadingAction = true);

    try {
      await action();
      if (mounted) show(msg);
    } catch (e) {
      debugPrint("Users Action Error: $e");
      if (mounted) show("حصل خطأ ❌");
    }

    if (mounted) {
      setState(() => loadingAction = false);
    }
  }

  Future<bool> confirm(String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("تأكيد"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future unlockCourse(String userId, String courseId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "unlockedCourses": FieldValue.arrayUnion([courseId]),
      "subscribed": true,
    }, SetOptions(merge: true));
  }

  Future lockCourse(String userId, String courseId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "unlockedCourses": FieldValue.arrayRemove([courseId]),
    }, SetOptions(merge: true));
  }

  Future toggleSubscription(String userId, bool current) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "subscribed": !current,
    }, SetOptions(merge: true));
  }

  Future blockUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "blocked": true
    }, SetOptions(merge: true));
  }

  Future activateUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "blocked": false
    }, SetOptions(merge: true));
  }

  Future makeAdmin(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "isAdmin": true
    }, SetOptions(merge: true));
  }

  Future removeAdmin(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "isAdmin": false
    }, SetOptions(merge: true));
  }

  Future approveInstructor(String userId) async {
    bool ok = await confirm("قبول المدرس؟");
    if (!ok) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "instructorApproved": true,
      "instructorRequest": false,
      "isInstructor": true,
    }, SetOptions(merge: true));
  }

  Future rejectInstructor(String userId) async {
    bool ok = await confirm("رفض الطلب؟");
    if (!ok) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      "instructorApproved": false,
      "instructorRequest": false,
      "isInstructor": false,
    }, SetOptions(merge: true));
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.gold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {

    final query = search.trim().toLowerCase();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
      builder: (context, adminSnap) {

        if (!adminSnap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          );
        }

        final adminData = adminSnap.data!.data() as Map<String, dynamic>? ?? {};
        final isCurrentAdmin = adminData['isAdmin'] == true;

        if (!isCurrentAdmin) {
          return const Scaffold(
            body: Center(
              child: Text("غير مسموح بالدخول", style: TextStyle(color: Colors.white)),
            ),
            backgroundColor: AppColors.background,
          );
        }

        return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "👥 Users Dashboard",
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.05), shape: BoxShape.circle),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: const SizedBox()),
            ),
          ),
          Column(
            children: [

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      hint: "Search by email...",
                      controller: searchController,
                      onChanged: (val) {
                        setState(() => search = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151515),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCourseId,
                              hint: const Text("اختر كورس للتحكم في الصلاحيات", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              dropdownColor: AppColors.black,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white),
                              items: snapshot.data!.docs.map((c) {
                                var data = c.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text((data['title'] ?? "").toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => selectedCourseId = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              if (loadingAction)
                const LinearProgressIndicator(color: AppColors.gold, backgroundColor: Colors.transparent),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: usersStream,
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                        ),
                      );
                    }

                    var users = snapshot.data!.docs;

                    var filtered = users.where((u) {
                      var data = u.data() as Map<String, dynamic>;
                      var email = (data['email'] ?? "").toString().toLowerCase();
                      return query.isEmpty || email.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text("لا يوجد مستخدمين",
                            style: TextStyle(color: Colors.white)),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {

                        var u = filtered[index];
                        var data = u.data() as Map<String, dynamic>;

                        String email = (data['email'] ?? "No Email").toString();
                        String phone = (data['phone'] ?? "").toString();
                        String createdAt = (data['createdAt'] ?? "").toString();
                        int coursesCount = (data['unlockedCourses'] is List)
                            ? (data['unlockedCourses'] as List).length
                            : 0;

                        bool isBlocked = data['blocked'] ?? false;
                        bool isAdmin = data['isAdmin'] ?? false;
                        bool subscribed = data['subscribed'] ?? false;
                        bool instructorRequest = data['instructorRequest'] ?? false;
                        bool instructorApproved = data['instructorApproved'] ?? false;
                        bool isMe = u.id == currentUserId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isMe ? AppColors.gold.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? AppColors.gold : Colors.grey[800],
                              child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.black),
                            ),
                            title: Text(email,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: (isBlocked ? Colors.red : Colors.green).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: (isBlocked ? Colors.red : Colors.green).withOpacity(0.5), width: 0.5)),
                                      child: Text(isBlocked ? "محظور" : "نشط", style: TextStyle(color: isBlocked ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    if (subscribed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 0.5)),
                                        child: const Text("VIP", style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    if (instructorApproved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.5), width: 0.5)),
                                        child: const Text("مدرس", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    if (instructorRequest && !instructorApproved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.5), width: 0.5)),
                                        child: const Text("طلب مدرس", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text("📞 $phone | 📚 $coursesCount كورسات", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),

                            trailing: PopupMenuButton<String>(
                              color: AppColors.black,
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              onSelected: (value) async {
                                switch (value) {
                                  case "toggleSub":
                                    runAction(
                                      () => toggleSubscription(u.id, subscribed),
                                      "تم التغيير 💳",
                                    );
                                    break;

                                  case "block":
                                    if (await confirm("تأكيد الحظر؟")) {
                                      runAction(() => blockUser(u.id), "تم الحظر");
                                    }
                                    break;

                                  case "activate":
                                    if (await confirm("تأكيد التفعيل؟")) {
                                      runAction(() => activateUser(u.id), "تم التفعيل");
                                    }
                                    break;

                                  case "makeAdmin":
                                    if (!isMe && await confirm("تأكيد إضافة ادمن؟")) {
                                      runAction(() => makeAdmin(u.id), "تم إضافة ادمن 👑");
                                    }
                                    break;

                                  case "removeAdmin":
                                    if (!isMe && await confirm("تأكيد إزالة الادمن؟")) {
                                      runAction(() => removeAdmin(u.id), "تم إزالة الادمن ❌");
                                    }
                                    break;

                                  case "unlockCourse":
                                    if (selectedCourseId != null && await confirm("تأكيد فتح الكورس؟")) {
                                      runAction(
                                        () => unlockCourse(u.id, selectedCourseId!),
                                        "تم فتح الكورس 🎉",
                                      );
                                    }
                                    break;

                                  case "lockCourse":
                                    if (selectedCourseId != null && await confirm("تأكيد قفل الكورس؟")) {
                                      runAction(
                                        () => lockCourse(u.id, selectedCourseId!),
                                        "تم قفل الكورس 🔒",
                                      );
                                    }
                                    break;

                                  case "approveInstructor":
                                    runAction(() => approveInstructor(u.id), "تم قبول المدرس 🎓");
                                    break;

                                  case "rejectInstructor":
                                    runAction(() => rejectInstructor(u.id), "تم رفض الطلب ❌");
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: "toggleSub",
                                  child: Text("💳 اشتراك"),
                                ),
                                const PopupMenuItem(
                                  value: "block",
                                  child: Text("🚫 حظر"),
                                ),
                                const PopupMenuItem(
                                  value: "activate",
                                  child: Text("✅ تفعيل"),
                                ),
                                if (selectedCourseId != null)
                                  const PopupMenuItem(
                                    value: "unlockCourse",
                                    child: Text("📚 فتح الكورس"),
                                  ),
                                if (selectedCourseId != null)
                                  const PopupMenuItem(
                                    value: "lockCourse",
                                    child: Text("🔒 قفل الكورس"),
                                  ),
                                if (!isAdmin && !isMe)
                                  const PopupMenuItem(
                                    value: "makeAdmin",
                                    child: Text("👑 Make Admin"),
                                  ),
                                if (isAdmin && !isMe)
                                  const PopupMenuItem(
                                    value: "removeAdmin",
                                    child: Text("❌ Remove Admin"),
                                  ),
                                if (instructorRequest && !instructorApproved)
                                  const PopupMenuItem(
                                    value: "approveInstructor",
                                    child: Text("🎓 قبول كمدرس"),
                                  ),
                                if (instructorRequest && !instructorApproved)
                                  const PopupMenuItem(
                                    value: "rejectInstructor",
                                    child: Text("❌ رفض الطلب"),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}