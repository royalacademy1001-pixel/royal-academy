part of 'users_page.dart';

extension UsersActions on _UsersPageState {
  Future<void> _syncLinkedStudent(
    String userId,
    Map<String, dynamic> data, {
    Map<String, dynamic>? extra,
  }) async {
    final studentId = UsersLogic.text(data['studentId']);
    if (studentId.isEmpty) return;

    final payload = <String, dynamic>{
      "linkedUserId": userId,
      "name": UsersLogic.text(data['name']),
      "phone": UsersLogic.text(data['phone']),
      "image": UsersLogic.text(data['image']),
      "isVIP": UsersLogic.isVip(data),
      "blocked": UsersLogic.isBlocked(data),
      "subscribed": UsersLogic.isSubscribed(data),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (extra != null) {
      payload.addAll(extra);
    }

    await FirebaseService.firestore
        .collection("students")
        .doc(studentId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _toggleSubscription(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "subscribed": next,
        "subscriptionUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "subscribed": next,
          "subscriptionUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تفعيل الاشتراك ✅" : "تم إلغاء الاشتراك ❌");

    await _refreshUsers();
  }

  Future<void> _toggleVip(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "isVIP": next,
        "vipUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "isVIP": next,
          "vipUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تفعيل VIP ⭐" : "تم إلغاء VIP");

    await _refreshUsers();
  }

  Future<void> _toggleBlock(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "blocked": next,
        "blockedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "blocked": next,
          "blockedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم حظر المستخدم 🚫" : "تم فك الحظر ✅");

    await _refreshUsers();
  }

  Future<void> _makeAdmin(
    String userId,
    bool current,
    Map<String, dynamic> data,
  ) async {
    final next = !current;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "isAdmin": next,
        "adminUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "isAdmin": next,
          "adminUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, next ? "تم تحويله Admin 👑" : "تم إزالة Admin ❌");

    await _refreshUsers();
  }

  Future<void> _approveInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": true,
        "instructorRequest": false,
        "isInstructor": true,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": true,
          "instructorRequest": false,
          "isInstructor": true,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم قبول المدرس 🎓");

    await _refreshUsers();
  }

  Future<void> _rejectInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": false,
        "instructorRequest": false,
        "isInstructor": false,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": false,
          "instructorRequest": false,
          "isInstructor": false,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم رفض طلب المدرس ❌");

    await _refreshUsers();
  }

  Future<void> _removeInstructor(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "instructorApproved": false,
        "instructorRequest": false,
        "isInstructor": false,
        "instructorUpdatedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "instructorApproved": false,
          "instructorRequest": false,
          "isInstructor": false,
          "instructorUpdatedAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم إلغاء صفة المدرس 🚫");

    await _refreshUsers();
  }

  Future<void> _unlockCourse(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    final courseId = selectedCourseId!;
    final title = selectedCourseTitle.isEmpty ? "الكورس" : selectedCourseTitle;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "unlockedCourses": FieldValue.arrayUnion([courseId]),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "lastUnlockedCourseId": courseId,
          "lastUnlockedCourseTitle": title,
        },
      );
    }, "تم فتح $title 🔓");

    await _refreshUsers();
  }

  Future<void> _lockCourse(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    final courseId = selectedCourseId!;
    final title = selectedCourseTitle.isEmpty ? "الكورس" : selectedCourseTitle;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "unlockedCourses": FieldValue.arrayRemove([courseId]),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "lastLockedCourseId": courseId,
          "lastLockedCourseTitle": title,
        },
      );
    }, "تم قفل $title 🔒");

    await _refreshUsers();
  }

  Future<void> _markAttendance(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!UsersLogic.isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

    await runAction(() async {
      await FirebaseService.firestore.collection("attendance").add({
        "userId": userId,
        "studentId": UsersLogic.text(data['studentId']),
        "name": UsersLogic.text(data['name']),
        "phone": UsersLogic.text(data['phone']),
        "isVIP": true,
        "status": "present",
        "date": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
        "source": "users_page",
      });

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "lastAttendanceAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _syncLinkedStudent(
        userId,
        data,
        extra: {
          "lastAttendanceAt": FieldValue.serverTimestamp(),
        },
      );
    }, "تم تسجيل الحضور ✅");

    await _refreshUsers();
  }

  Future<void> _addResult(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!UsersLogic.isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

    if (selectedCourseId == null || selectedCourseId!.isEmpty) {
      show("اختر كورس أولاً");
      return;
    }

    if (!mounted) return;

    final scoreController = TextEditingController();

    try {
      final ok = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.black,
              title: const Text(
                "📊 إضافة نتيجة",
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "ادخل الدرجة",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("حفظ"),
                ),
              ],
            ),
          ) ??
          false;

      if (!ok) return;

      final score = int.tryParse(scoreController.text.trim()) ?? 0;
      if (score <= 0) {
        show("الدرجة غير صحيحة");
        return;
      }

      final courseId = selectedCourseId!;
      final courseTitle = selectedCourseTitle.isEmpty ? "" : selectedCourseTitle;

      await runAction(() async {
        await FirebaseService.firestore.collection("results").add({
          "userId": userId,
          "studentId": UsersLogic.text(data['studentId']),
          "name": UsersLogic.text(data['name']),
          "phone": UsersLogic.text(data['phone']),
          "courseId": courseId,
          "courseTitle": courseTitle,
          "score": score,
          "isVIP": true,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          "source": "users_page",
        });

        await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(userId)
            .set({
          "lastResultScore": score,
          "lastResultCourseId": courseId,
          "lastResultCourseTitle": courseTitle,
          "lastResultAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _syncLinkedStudent(
          userId,
          data,
          extra: {
            "lastResultScore": score,
            "lastResultCourseId": courseId,
            "lastResultCourseTitle": courseTitle,
            "lastResultAt": FieldValue.serverTimestamp(),
          },
        );
      }, "تم إضافة النتيجة ✅");

      await _refreshUsers();
    } finally {
      scoreController.dispose();
    }
  }

  Future<void> _linkStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!UsersLogic.isVip(data)) {
      show("هذه العملية متاحة لطلاب VIP فقط");
      return;
    }

    try {
      final studentsSnap = await FirebaseService.firestore
          .collection("students")
          .orderBy("createdAt", descending: true)
          .get();

      final students = studentsSnap.docs.map((doc) {
        final map = UsersLogic.safeMap(doc.data());
        map["_id"] = doc.id;
        return map;
      }).toList();

      if (students.isEmpty) {
        show("لا يوجد طلاب");
        return;
      }

      if (!mounted) return;

      String query = "";
      Map<String, dynamic>? selected;

      await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = students.where((student) {
              final name = UsersLogic.text(student['name']).toLowerCase();
              final phone = UsersLogic.text(student['phone']).toLowerCase();
              final id = UsersLogic.text(student['_id']).toLowerCase();

              return query.isEmpty ||
                  name.contains(query) ||
                  phone.contains(query) ||
                  id.contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.black,
              title: const Text(
                "🔗 ربط الطالب",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.toLowerCase().trim();
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "ابحث في الطلاب...",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "لا يوجد طلاب",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final s = filtered[index];
                                return ListTile(
                                  title: Text(
                                    UsersLogic.text(s['name']).isEmpty
                                        ? "Student"
                                        : UsersLogic.text(s['name']),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    UsersLogic.text(s['phone']),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () {
                                    selected = {
                                      "id": UsersLogic.text(s['_id']),
                                      "name": UsersLogic.text(s['name']),
                                      "phone": UsersLogic.text(s['phone']),
                                    };
                                    Navigator.pop(dialogContext);
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
        ),
      );

      if (selected == null) return;

      await runAction(() async {
        await FirebaseService.firestore
            .collection(AppConstants.users)
            .doc(userId)
            .set({
          "name": selected!["name"],
          "phone": selected!["phone"],
          "studentId": selected!["id"],
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await FirebaseService.firestore
            .collection("students")
            .doc(selected!["id"])
            .set({
          "linkedUserId": userId,
          "name": selected!["name"],
          "phone": selected!["phone"],
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }, "تم الربط ✅");

      await _refreshUsers();
    } catch (e) {
      debugPrint("Link Student Error: $e");
      if (mounted) show("حصل خطأ ❌");
    }
  }

  Future<void> _unlinkStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final studentId = UsersLogic.text(data['studentId']);
    if (studentId.isEmpty) return;

    await runAction(() async {
      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(userId)
          .set({
        "studentId": "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseService.firestore.collection("students").doc(studentId).set({
        "linkedUserId": "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }, "تم فصل الربط ✅");

    await _refreshUsers();
  }

  Future<void> _editStudent(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentPage(
          userId: userId,
          data: Map<String, dynamic>.from(data),
        ),
      ),
    );

    await _refreshUsers();
  }
}