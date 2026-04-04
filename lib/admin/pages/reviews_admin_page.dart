// 🔥 REVIEWS ADMIN PAGE (PRO MAX++ FINAL SAFE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class ReviewsAdminPage extends StatefulWidget {
  final String courseId;

  const ReviewsAdminPage({super.key, required this.courseId});

  @override
  State<ReviewsAdminPage> createState() =>
      _ReviewsAdminPageState();
}

class _ReviewsAdminPageState extends State<ReviewsAdminPage> {

  String search = "";
  int filterRating = 0;

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future deleteReview(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
      show("تم الحذف ✅");
    } catch (_) {
      show("خطأ ❌");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("🛠️ إدارة التقييمات",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (v) =>
                  setState(() => search = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث...",
                filled: true,
                fillColor: AppColors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          /// ⭐ FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return GestureDetector(
                onTap: () => setState(() => filterRating = i),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: filterRating == i
                        ? AppColors.gold
                        : AppColors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    i == 0 ? "All" : "$i⭐",
                    style: TextStyle(
                      color: filterRating == i
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          /// 🔥 LIST + STATS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.reviews)
                  .where('courseId',
                      isEqualTo: widget.courseId)
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
                    child: Text("لا يوجد تقييمات",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                /// 🔥 FILTER
                docs = docs.where((d) {
                  var data =
                      d.data() as Map<String, dynamic>? ?? {};

                  int r = data['rating'] ?? 0;
                  String text =
                      (data['text'] ?? data['comment'] ?? "")
                          .toString()
                          .toLowerCase();

                  if (filterRating != 0 && r != filterRating) {
                    return false;
                  }

                  if (search.isNotEmpty &&
                      !text.contains(search)) {
                    return false;
                  }

                  return true;
                }).toList();

                /// ⭐ CALCULATE AVG
                double avg = 0;
                for (var d in docs) {
                  avg += (d['rating'] ?? 0);
                }
                avg = avg / docs.length;

                return Column(
                  children: [

                    /// ⭐ HEADER
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber),
                          const SizedBox(width: 5),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                          const SizedBox(width: 5),
                          Text("(${docs.length})",
                              style: const TextStyle(
                                  color: Colors.grey)),
                        ],
                      ),
                    ),

                    /// LIST
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {

                          var doc = docs[index];
                          var data = doc.data()
                                  as Map<String, dynamic>? ??
                              {};

                          int r = data['rating'] ?? 0;
                          String text =
                              data['text'] ??
                                  data['comment'] ??
                                  "";

                          return Container(
                            margin:
                                const EdgeInsets.only(
                                    bottom: 10),
                            padding:
                                const EdgeInsets.all(12),
                            decoration:
                                AppColors.premiumCard,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [

                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 18,
                                          color: i < r
                                              ? Colors.amber
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete,
                                          color:
                                              Colors.red),
                                      onPressed: () =>
                                          deleteReview(
                                              doc),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  text,
                                  style: const TextStyle(
                                      color: Colors.white),
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