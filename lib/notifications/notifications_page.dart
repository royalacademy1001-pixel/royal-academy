import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 🔥 Core
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

// 🔥 Pages
import '../course_details_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  bool loadingAction = false;

  /// ================= TIME =================
  String formatTime(Timestamp? timestamp) {
    try {
      if (timestamp == null) return "";
      return DateFormat('dd MMM - hh:mm a')
          .format(timestamp.toDate());
    } catch (_) {
      return "";
    }
  }

  /// ================= ICON =================
  IconData getIcon(String title) {
    if (title.contains("اشتراك")) return Icons.workspace_premium;
    if (title.contains("دفع")) return Icons.payments;
    if (title.contains("كورس")) return Icons.menu_book;
    if (title.contains("درس")) return Icons.play_circle_fill;
    return Icons.notifications;
  }

  /// ================= NAV =================
  void handleClick(BuildContext context, Map<String, dynamic> data) {
    try {
      final courseId = (data['courseId'] ?? "").toString();

      if (courseId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailsPage(
              title: data['title'] ?? "",
              courseId: courseId,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  /// ================= SEEN =================
  Future markAsSeen(String id) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .doc(id)
          .update({"seen": true});
    } catch (_) {}
  }

  /// ================= MARK ALL =================
  Future markAllAsRead(List docs) async {
    if (loadingAction) return;

    setState(() => loadingAction = true);

    try {
      final batch = FirebaseService.firestore.batch();

      for (var d in docs) {
        final data = d.data() as Map<String, dynamic>;
        if (!(data['seen'] ?? false)) {
          batch.update(d.reference, {"seen": true});
        }
      }

      await batch.commit();
    } catch (_) {}

    if (mounted) {
      setState(() => loadingAction = false);
    }
  }

  /// ================= DELETE =================
  Future deleteNotification(String id) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .doc(id)
          .delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged")),
      );
    }

    final query = FirebaseService.firestore
        .collection(AppConstants.notifications)
        .orderBy("createdAt", descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.black,
        title: const Text(
          "🔔 الإشعارات",
          style: TextStyle(color: AppColors.gold),
        ),

        actions: [
          loadingAction
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.done_all,
                      color: AppColors.gold),
                  onPressed: () async {
                    try {
                      final snap = await query.get();
                      final docs = snap.docs.where((doc) {
                        final data = doc.data();
                        final userId = (data['userId'] ?? "").toString();
                        final type = (data['type'] ?? "").toString();
                        return userId == user.uid || type == "all";
                      }).toList();
                      await markAllAsRead(docs);
                    } catch (_) {}
                  },
                ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.gold),
            );
          }

          final allDocs = snapshot.data!.docs;

          final notifications = allDocs.where((doc) {
            final data = doc.data();

            final userId = (data['userId'] ?? "").toString();
            final type = (data['type'] ?? "").toString();

            return userId == user.uid || type == "all";
          }).toList();

          int unreadCount = notifications
              .where((d) => !(d.data()['seen'] ?? false))
              .length;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "لا يوجد إشعارات حالياً",
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async {
              await Future.delayed(
                  const Duration(milliseconds: 500));
            },

            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length +
                  (unreadCount > 0 ? 1 : 0),
              itemBuilder: (context, index) {

                if (unreadCount > 0 && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "🔴 $unreadCount إشعار جديد",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final realIndex =
                    unreadCount > 0 ? index - 1 : index;

                final doc = notifications[realIndex];
                final data = doc.data();

                final title =
                    (data['title'] ?? "").toString();
                final body =
                    (data['body'] ?? "").toString();
                final time = data['createdAt'];
                final seen = data['seen'] ?? false;

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      deleteNotification(doc.id),

                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),

                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(18),

                    onTap: () async {
                      if (!seen) {
                        await markAsSeen(doc.id);
                      }
                      handleClick(context, data);
                    },

                    child: AnimatedContainer(
                      duration: AppColors.fast,
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      padding:
                          const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: seen
                            ? AppColors.black
                            : AppColors.gold
                                .withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: seen
                              ? Colors.grey.shade800
                              : AppColors.gold,
                        ),
                        boxShadow:
                            seen ? [] : AppColors.goldShadow,
                      ),

                      child: Row(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold
                                  .withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              getIcon(title),
                              color: AppColors.gold,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  title,
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  body,
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.grey,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  formatTime(time),
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!seen)
                            const Icon(Icons.circle,
                                size: 10,
                                color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}