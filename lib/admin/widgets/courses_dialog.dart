// 🔥 FINAL PRO++ COURSES DIALOG (ULTIMATE VERSION 2026)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

void showCoursesDialog(
  BuildContext context, {
  required String userId,
  required bool unlock,
  required Function(List<String> courseIds) onSelect, // 🔥 MULTI SELECT
}) {

  String search = "";
  Timer? debounce;
  bool loading = false;

  List userCourses = [];
  List<String> selectedCourses = [];

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseService.firestore
                .collection(AppConstants.users)
                .doc(userId)
                .get(),
            builder: (context, userSnap) {

              if (userSnap.hasData) {
                var data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                userCourses = unlock
                    ? (data['unlockedCourses'] ?? [])
                    : (data['enrolledCourses'] ?? []);
              }

              return Stack(
                children: [
                  AlertDialog(
                    backgroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unlock ? "🔓 فتح كورسات" : "📚 إضافة كورسات",
                          style: const TextStyle(color: AppColors.gold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "اختار أكتر من كورس مرة واحدة",
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),

                    content: SizedBox(
                      width: double.maxFinite,
                      height: 450,
                      child: Column(
                        children: [

                          /// 🔍 SEARCH
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "🔍 ابحث عن كورس...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: AppColors.darkGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              if (debounce?.isActive ?? false) {
                                debounce!.cancel();
                              }
                              debounce = Timer(
                                  const Duration(milliseconds: 300), () {
                                setState(() => search = val);
                              });
                            },
                          ),

                          const SizedBox(height: 8),

                          /// 🔢 COUNT
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "عدد النتائج: ",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// 📚 LIST
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseService.firestore
                                  .collection(AppConstants.courses)
                                  .orderBy("createdAt", descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {

                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.gold),
                                  );
                                }

                                var courses = snapshot.data!.docs;

                                var filtered = courses.where((c) {
                                  var data =
                                      c.data() as Map<String, dynamic>;

                                  String title =
                                      (data['title'] ?? "").toLowerCase();

                                  return search.isEmpty ||
                                      title.contains(search.toLowerCase());
                                }).toList();

                                if (filtered.isEmpty) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.search_off,
                                          color: Colors.grey, size: 40),
                                      SizedBox(height: 10),
                                      Text(
                                        "لا يوجد نتائج",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  );
                                }

                                return ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {

                                    var c = filtered[i];
                                    var data =
                                        c.data() as Map<String, dynamic>;

                                    String image =
                                        (data['image'] ?? "").toString();

                                    bool alreadyAdded =
                                        userCourses.contains(c.id);

                                    bool selected =
                                        selectedCourses.contains(c.id);

                                    double price =
                                        (data['price'] ?? 0).toDouble();

                                    bool vip = data['isVIP'] == true;

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.gold.withValues(alpha: 0.1)
                                            : AppColors.black,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.gold
                                              : alreadyAdded
                                                  ? Colors.grey
                                                  : Colors.white10,
                                        ),
                                      ),
                                      child: ListTile(

                                        leading: image.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  image,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.school),
                                                ),
                                              )
                                            : const Icon(Icons.school,
                                                color: Colors.white),

                                        title: Text(
                                          data['title'] ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alreadyAdded
                                                  ? "مضاف بالفعل ✅"
                                                  : "📚 ${data['lessonsCount'] ?? 0} درس",
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              price == 0
                                                  ? "مجاني"
                                                  : "$price جنيه",
                                              style: TextStyle(
                                                color: price == 0
                                                    ? Colors.green
                                                    : AppColors.gold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),

                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (vip)
                                              const Icon(Icons.star,
                                                  color: Colors.amber, size: 16),
                                            const SizedBox(width: 6),
                                            Checkbox(
                                              value: selected,
                                              onChanged: alreadyAdded
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        if (selected) {
                                                          selectedCourses
                                                              .remove(c.id);
                                                        } else {
                                                          selectedCourses
                                                              .add(c.id);
                                                        }
                                                      });
                                                    },
                                              activeColor: AppColors.gold,
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

                          const SizedBox(height: 10),

                          /// ✅ CONFIRM BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: selectedCourses.isEmpty || loading
                                  ? null
                                  : () async {
                                      setState(() => loading = true);

                                      Navigator.pop(context);
                                      onSelect(selectedCourses);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                  "تأكيد (${selectedCourses.length})"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 🔥 LOADING
                  if (loading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    },
  );
}