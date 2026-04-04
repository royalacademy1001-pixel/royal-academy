// 🔥 FINAL COMMENTS PAGE (PRO MAX++ ULTRA UPGRADED + REPLIES + CACHE FIXED)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

class CommentsPage extends StatefulWidget {
  final String lessonId;

  const CommentsPage({super.key, required this.lessonId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {

  final TextEditingController controller = TextEditingController();

  bool sending = false;

  Map<String, Map<String, dynamic>> usersCache = {};

  DateTime? lastSend;

  // ================= ADD COMMENT =================
  Future addComment() async {

    if (sending) return;

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    String text = controller.text.trim();

    if (text.isEmpty) return;

    if (text.length > AppConstants.maxCommentLength) {
      show("التعليق طويل جدًا ❌");
      return;
    }

    if (lastSend != null &&
        DateTime.now().difference(lastSend!).inSeconds < 2) {
      show("استنى ثانيتين ⏳");
      return;
    }

    setState(() => sending = true);

    try {

      await FirebaseService.firestore
          .collection(AppConstants.comments)
          .add({
        "lessonId": widget.lessonId,
        "userId": user.uid,
        "text": text,
        "likes": [],
        "createdAt": FieldValue.serverTimestamp(),
      });

      controller.clear();
      lastSend = DateTime.now();

    } catch (_) {}

    if (mounted) setState(() => sending = false);
  }

  // ================= LIKE =================
  Future toggleLike(DocumentSnapshot doc) async {

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    List likes = (doc['likes'] ?? []);

    bool isLiked = likes.contains(user.uid);

    await doc.reference.update({
      "likes": isLiked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid])
    });
  }

  // ================= DELETE =================
  Future deleteComment(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
    } catch (_) {}
  }

  // ================= LOAD USER =================
  Future<Map<String, dynamic>> getUser(String uid) async {

    if (uid.isEmpty) return {};

    if (usersCache.containsKey(uid)) {
      return usersCache[uid]!;
    }

    try {
      var doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(uid)
          .get();

      var data = doc.data() ?? {};

      usersCache[uid] = data;

      return data;
    } catch (_) {
      return {};
    }
  }

  // ================= FORMAT =================
  String formatTime(Timestamp? t) {
    try {
      if (t == null) return "";
      return DateFormat('dd MMM - hh:mm a').format(t.toDate());
    } catch (_) {
      return "";
    }
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("💬 التعليقات",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.comments)
                  .where('lessonId', isEqualTo: widget.lessonId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold),
                  );
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("لا يوجد تعليقات",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    var doc = docs[index];
                    var data =
                        doc.data() as Map<String, dynamic>? ?? {};

                    List likes = data['likes'] ?? [];

                    bool isLiked =
                        user != null && likes.contains(user.uid);

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getUser(data['userId'] ?? ""),
                      builder: (context, userSnap) {

                        var userData = userSnap.data ?? {};

                        String name = userData['name'] ?? "User";
                        String avatar =
                            userData['image'] ??
                                AppConstants.defaultAvatar;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: AppColors.premiumCard,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        NetworkImage(avatar),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatTime(data['createdAt']),
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                data['text'] ?? "",
                                style: const TextStyle(
                                  color: AppColors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [

                                  GestureDetector(
                                    onTap: () => toggleLike(doc),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          size: 18,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text("${likes.length}",
                                            style:
                                                const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  ReplyWidget(commentDoc: doc),

                                  const Spacer(),

                                  if (user != null &&
                                      user.uid == data['userId'])
                                    GestureDetector(
                                      onTap: () => deleteComment(doc),
                                      child: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT
          Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.black,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => addComment(),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "اكتب تعليق...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send,
                            color: AppColors.gold),
                        onPressed: addComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= REPLY =================
class ReplyWidget extends StatefulWidget {
  final DocumentSnapshot commentDoc;

  const ReplyWidget({super.key, required this.commentDoc});

  @override
  State<ReplyWidget> createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends State<ReplyWidget> {

  bool open = false;
  final controller = TextEditingController();
  bool sending = false;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        GestureDetector(
          onTap: () => setState(() => open = !open),
          child: const Text("رد",
              style: TextStyle(color: Colors.blue)),
        ),

        if (open)
          Column(
            children: [

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "اكتب رد...",
                        hintStyle:
                            TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send,
                              color: AppColors.gold),
                          onPressed: () async {

                            if (sending) return;

                            final user =
                                FirebaseService.auth.currentUser;
                            if (user == null) return;

                            String text =
                                controller.text.trim();

                            if (text.isEmpty) return;

                            setState(() => sending = true);

                            try {
                              await widget.commentDoc.reference
                                  .collection("replies")
                                  .add({
                                "userId": user.uid,
                                "text": text,
                                "createdAt":
                                    FieldValue.serverTimestamp(),
                              });

                              controller.clear();
                            } catch (_) {}

                            if (mounted) {
                              setState(() => sending = false);
                            }
                          },
                        ),
                ],
              ),

              StreamBuilder<QuerySnapshot>(
                stream: widget.commentDoc.reference
                    .collection("replies")
                    .orderBy("createdAt")
                    .snapshots(),
                builder: (context, snap) {

                  if (!snap.hasData) return const SizedBox();

                  return Column(
                    children: snap.data!.docs.map((r) {

                      var d =
                          r.data() as Map<String, dynamic>? ?? {};

                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          d['text'] ?? "",
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}