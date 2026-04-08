// 🔥 FINAL ULTRA NOTIFICATIONS ADMIN PAGE (PRO MAX++ ELITE UPGRADED SAFE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:ui';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class NotificationsAdminPage extends StatefulWidget {
  const NotificationsAdminPage({super.key});

  @override
  State<NotificationsAdminPage> createState() => _NotificationsAdminPageState();
}

class _NotificationsAdminPageState extends State<NotificationsAdminPage> {
  final title = TextEditingController();
  final body = TextEditingController();
  final search = TextEditingController();

  String? selectedCourseId;
  String? selectedUserId;

  String sendType = "all";

  bool loading = false;
  bool sendingNow = false;

  DateTime? lastSendTime;

  // ================== SEND ==================
  Future sendNotification() async {
    if (sendingNow) return;

    final t = title.text.trim();
    final b = body.text.trim();

    if (t.isEmpty || b.isEmpty) {
      show("اكتب البيانات ❗");
      return;
    }

    if (sendType == "course" && selectedCourseId == null) {
      show("اختار الكورس ❗");
      return;
    }

    if (sendType == "user" && selectedUserId == null) {
      show("اختار المستخدم ❗");
      return;
    }

    if (lastSendTime != null &&
        DateTime.now().difference(lastSendTime!).inSeconds < 3) {
      show("استنى ثواني قبل الإرسال ⚠️");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      sendingNow = true;
    });

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable("sendNotification");

      if (sendType == "all") {
        await FirebaseService.firestore
            .collection(AppConstants.notifications)
            .add({
          "title": t,
          "body": b,
          "courseId": null,
          "userId": null,
          "type": "all",
          "seen": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await callable.call({
          "title": t,
          "body": b,
        });
      }

      if (sendType == "course") {
        var users = await FirebaseService.firestore
            .collection(AppConstants.users)
            .get();

        for (var u in users.docs) {
          var data = u.data();

          List courses = data['enrolledCourses'] ?? [];

          if (courses.contains(selectedCourseId)) {
            await FirebaseService.firestore
                .collection(AppConstants.notifications)
                .add({
              "title": t,
              "body": b,
              "courseId": selectedCourseId,
              "userId": u.id,
              "type": "course",
              "seen": false,
              "createdAt": FieldValue.serverTimestamp(),
            });
          }
        }

        await callable.call({
          "title": t,
          "body": b,
          "data": {
            "courseId": selectedCourseId,
          }
        });
      }

      if (sendType == "user") {
        await FirebaseService.firestore
            .collection(AppConstants.notifications)
            .add({
          "title": t,
          "body": b,
          "courseId": null,
          "userId": selectedUserId,
          "type": "user",
          "seen": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await callable.call({
          "title": t,
          "body": b,
          "userId": selectedUserId,
        });
      }

      lastSendTime = DateTime.now();

      title.clear();
      body.clear();

      setState(() {
        selectedCourseId = null;
        selectedUserId = null;
      });

      show("تم إرسال الإشعار 🔥");
    } catch (e) {
      show("حصل خطأ ❌");
    }

    setState(() {
      loading = false;
      sendingNow = false;
    });
  }

  // ================== DELETE ==================
  Future deleteNotification(String id) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .doc(id)
          .delete();

      show("تم الحذف ❌");
    } catch (_) {
      show("فشل الحذف ❌");
    }
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "🔔 إدارة الإشعارات",
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildSendCard(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: input("🔍 ابحث في السجل..."),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "📜 سجل الإشعارات المرسلة",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildHistory(query),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (loading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendCard() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              const Text(
                "إرسال إشعار جديد",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: title,
            style: const TextStyle(color: AppColors.white),
            decoration: input("عنوان الإشعار"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: body,
            maxLines: 3,
            style: const TextStyle(color: AppColors.white),
            decoration: input("محتوى الإشعار التفصيلي"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: sendType, // ✅ بدل value
            dropdownColor: AppColors.black,
            style: const TextStyle(color: AppColors.white),
            decoration: input("إرسال إلى..."),
            items: const [
              DropdownMenuItem(
                  value: "all", child: Text("🌍 جميع مستخدمي التطبيق")),
              DropdownMenuItem(
                  value: "course", child: Text("🎓 طلاب كورس محدد")),
              DropdownMenuItem(value: "user", child: Text("👤 طالب معين فقط")),
            ],
            onChanged: (value) {
              setState(() {
                sendType = value!;
                selectedCourseId = null;
                selectedUserId = null;
              });
            },
          ),
          const SizedBox(height: 12),
          if (sendType == "course") _buildCourseDropdown(),
          if (sendType == "user") _buildUserDropdown(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: sendNotification,
              child: const Text(
                "🚀 بث الإشعار الآن",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.courses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }

        return DropdownButtonFormField<String>(
          initialValue: selectedCourseId, // ✅ بدل value
          dropdownColor: AppColors.black,
          style: const TextStyle(color: AppColors.white),
          decoration: input("اختر الكورس المستهدف"),
          items: snapshot.data!.docs.map((c) {
            final data = c.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: c.id,
              child: Text((data['title'] ?? "").toString()),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              selectedCourseId = v;
            });
          },
        );
      },
    );
  }

  Widget _buildUserDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseService.firestore.collection(AppConstants.users).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }

        return DropdownButtonFormField<String>(
          initialValue: selectedUserId, // ✅ بدل value
          dropdownColor: AppColors.black,
          style: const TextStyle(color: AppColors.white),
          decoration: input("اختر الطالب المستهدف"),
          items: snapshot.data!.docs.map((u) {
            final data = u.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: u.id,
              child: Text((data['email'] ?? "User").toString()),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              selectedUserId = v;
            });
          },
        );
      },
    );
  }

  Widget _buildHistory(String query) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.notifications)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }

        var list = snapshot.data!.docs;

        var filtered = list.where((n) {
          var data = n.data() as Map<String, dynamic>;

          String t = (data['title'] ?? "").toString().toLowerCase();
          String b = (data['body'] ?? "").toString().toLowerCase();

          return query.isEmpty || t.contains(query) || b.contains(query);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_rounded,
                    size: 50, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                const Text("لا يوجد إشعارات في السجل",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            var data = filtered[index].data() as Map<String, dynamic>;

            String type = (data['type'] ?? "all").toString();

            Timestamp? time = data['createdAt'];

            String date = time != null
                ? DateFormat('yyyy/MM/dd | HH:mm').format(time.toDate())
                : "";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Text(
                  (data['title'] ?? "").toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      (data['body'] ?? "").toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: type == "all"
                                ? Colors.blue.withValues(alpha: 0.1)
                                : type == "course"
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type == "all"
                                ? "🌍 للجميع"
                                : type == "course"
                                    ? "🎓 لطلاب كورس"
                                    : "👤 لطالب محدد",
                            style: TextStyle(
                                color: type == "all"
                                    ? Colors.blue
                                    : type == "course"
                                        ? Colors.orange
                                        : Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(date,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 22),
                  onPressed: () => deleteNotification(filtered[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.gold, width: 1),
      ),
    );
  }
}
