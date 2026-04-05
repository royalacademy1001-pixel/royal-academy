// 🔥 FINAL PRO COURSES DIALOG (SEARCH + IMAGE + UI)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

void showCoursesDialog(
  BuildContext context, {
  required String userId,
  required bool unlock,
  required Function(String courseId) onSelect,
}) {

  String search = "";

  List userCourses = [];

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

              return AlertDialog(
                backgroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: Text(
                  unlock ? "🔓 فتح كورس" : "📚 إضافة كورس",
                  style: const TextStyle(color: AppColors.gold),
                ),

                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [

                      /// 🔍 SEARCH
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "🔍 ابحث عن كورس...",
                          hintStyle:
                              const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: AppColors.darkGrey,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => search = val);
                        },
                      ),

                      const SizedBox(height: 10),

                      /// 📚 LIST
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseService.firestore
                              .collection(AppConstants.courses)
                              .snapshots(),
                          builder: (context, snapshot) {

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.gold),
                              );
                            }

                            var courses = snapshot.data!.docs;

                            /// 🔥 FILTER
                            var filtered = courses.where((c) {

                              var data =
                                  c.data() as Map<String, dynamic>;

                              String title =
                                  (data['title'] ?? "")
                                      .toLowerCase();

                              return search.isEmpty ||
                                  title.contains(search.toLowerCase());

                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text(
                                  "لا يوجد كورسات",
                                  style: TextStyle(color: Colors.white),
                                ),
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

                                return Opacity(
                                  opacity: alreadyAdded ? 0.5 : 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: AppColors.premiumCard,
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
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold),
                                      ),

                                      subtitle: Text(
                                        alreadyAdded
                                            ? "مضاف بالفعل ✅"
                                            : "📚 ${data['lessonsCount'] ?? 0} درس",
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),

                                      onTap: alreadyAdded
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                              onSelect(c.id);
                                            },
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
                ),
              );
            },
          );
        },
      );
    },
  );
}