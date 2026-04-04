// 🔥 REVIEWS PAGE (FINAL STABLE ULTRA SAFE + UX UPGRADE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

class ReviewsPage extends StatefulWidget {
  final String courseId;

  const ReviewsPage({super.key, required this.courseId});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {

  final controller = TextEditingController();

  int rating = 0;
  bool loading = false;

  DocumentSnapshot<Map<String, dynamic>>? myReview;

  @override
  void initState() {
    super.initState();
    loadMyReview();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// ================= LOAD =================
  Future loadMyReview() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    try {
      var res = await FirebaseService.firestore
          .collection(AppConstants.reviews)
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (res.docs.isNotEmpty) {
        myReview = res.docs.first;

        var data = myReview!.data() ?? {};

        rating = (data['rating'] ?? 0).toInt();
        controller.text =
            (data['text'] ?? data['comment'] ?? "").toString();

        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  /// ================= SUBMIT =================
  Future submit() async {

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    String text = controller.text.trim();

    if (rating == 0) {
      show("اختار تقييم ⭐");
      return;
    }

    if (text.isEmpty) {
      show("اكتب رأيك ✍️");
      return;
    }

    setState(() => loading = true);

    try {

      if (myReview != null) {
        await myReview!.reference.update({
          "rating": rating,
          "text": text,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      } else {
        var ref = await FirebaseService.firestore
            .collection(AppConstants.reviews)
            .add({
          "courseId": widget.courseId,
          "userId": user.uid,
          "rating": rating,
          "text": text,
          "createdAt": FieldValue.serverTimestamp(),
        });

        myReview = await ref.get();
      }

      show("تم الحفظ ✅");

    } catch (_) {
      show("خطأ ❌");
    }

    if (mounted) setState(() => loading = false);
  }

  /// ================= DELETE =================
  Future deleteReview() async {
    if (myReview == null) return;

    try {
      await myReview!.reference.delete();

      controller.clear();
      rating = 0;
      myReview = null;

      if (mounted) setState(() {});
      show("تم الحذف");
    } catch (_) {}
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget star(int i) {
    return GestureDetector(
      onTap: () => setState(() => rating = i),
      child: Icon(
        Icons.star,
        color: i <= rating ? Colors.amber : Colors.grey,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("⭐ التقييمات",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// ================= ADD =================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppColors.premiumCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children:
                      List.generate(5, (i) => star(i + 1)),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: controller,
                  maxLines: 2,
                  style:
                      const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "اكتب رأيك...",
                    hintStyle:
                        TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 10),

                loading
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [

                          Expanded(
                            child: ElevatedButton(
                              style: AppColors.goldButton,
                              onPressed: loading ? null : submit,
                              child: Text(
                                  myReview != null
                                      ? "تعديل"
                                      : "إرسال"),
                            ),
                          ),

                          if (myReview != null)
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: deleteReview,
                            ),
                        ],
                      ),
              ],
            ),
          ),

          /// ================= LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.reviews)
                  .where('courseId',
                      isEqualTo: widget.courseId)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("لا يوجد تقييمات",
                        style:
                            TextStyle(color: Colors.white)),
                  );
                }

                double total = 0;
                for (var d in docs) {
                  total += (d.data()['rating'] ?? 0);
                }

                double avg = total / docs.length;

                return Column(
                  children: [

                    Padding(
                      padding:
                          const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber),
                          const SizedBox(width: 5),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                          const SizedBox(width: 5),
                          Text("(${docs.length})",
                              style: const TextStyle(
                                  color: Colors.grey)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, i) {

                          var data = docs[i].data();

                          int r = (data['rating'] ?? 0);

                          return Container(
                            margin:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5),
                            padding:
                                const EdgeInsets.all(10),
                            decoration:
                                AppColors.premiumCard,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star,
                                        size: 16,
                                        color: i < r
                                            ? Colors.amber
                                            : Colors.grey),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  data['text'] ??
                                      data['comment'] ??
                                      "",
                                  style: const TextStyle(
                                      color:
                                          Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}