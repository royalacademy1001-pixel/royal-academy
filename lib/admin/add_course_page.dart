import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();

  bool isFree = true;
  bool loading = false;
  bool loadingUser = true;

  String? selectedCategoryId;

  Uint8List? imageBytes;
  String? imageName;

  final picker = ImagePicker();

  Map<String, dynamic> userData = {};

  Future loadUser() async {
    try {
      userData = await FirebaseService.getUserData();
    } catch (_) {}

    if (mounted) {
      setState(() => loadingUser = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  String _contentTypeFromName(String? name) {
    final lower = (name ?? "").toLowerCase();

    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".gif")) return "image/gif";
    if (lower.endsWith(".webp")) return "image/webp";
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";

    return "image/jpeg";
  }

  String _extensionFromName(String? name) {
    final lower = (name ?? "").toLowerCase();

    if (lower.endsWith(".png")) return ".png";
    if (lower.endsWith(".gif")) return ".gif";
    if (lower.endsWith(".webp")) return ".webp";
    if (lower.endsWith(".jpg")) return ".jpg";
    if (lower.endsWith(".jpeg")) return ".jpg";

    return ".jpg";
  }

  Future pickImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      imageName = picked.name;
      imageBytes = await picked.readAsBytes();

      if (mounted) setState(() {});
    } catch (e) {
      showSnack("فشل اختيار الصورة ❌");
    }
  }

  Future<String?> uploadImage() async {
    try {
      final bytes = imageBytes;
      if (bytes == null) return null;

      await FirebaseService.auth.currentUser?.reload();
      await FirebaseService.auth.currentUser?.getIdToken(true);

      final user = FirebaseService.auth.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .get();

      final userDataDoc = userDoc.data() ?? {};

      if (userDataDoc['blocked'] == true) return null;

      final fileName =
          "${user.uid}_${DateTime.now().microsecondsSinceEpoch}${_extensionFromName(imageName)}";

      final ref =
          FirebaseService.storage.ref().child("courses/images/$fileName");

      final metadata = SettableMetadata(
        contentType: _contentTypeFromName(imageName),
      );

      final task = ref.putData(bytes, metadata);
      await task.timeout(const Duration(seconds: 30));

      final url = await ref.getDownloadURL();
      if (url.isEmpty) return null;
      if (!url.startsWith("http")) return null;

      return url;
    } catch (e) {
      debugPrint("🔥 Upload Error: $e");
      return null;
    }
  }

  bool validate() {
    if (title.text.trim().isEmpty) {
      showSnack("اكتب اسم الكورس ❗");
      return false;
    }

    if (selectedCategoryId == null) {
      showSnack("اختار تصنيف ❗");
      return false;
    }

    if (!isFree) {
      int p = int.tryParse(price.text.trim()) ?? 0;
      if (p <= 0) {
        showSnack("سعر غير صحيح ❗");
        return false;
      }
    }

    return true;
  }

  bool canCreateCourse() {
    return userData['isAdmin'] == true ||
        userData['instructorApproved'] == true;
  }

  Future addCourse() async {
    if (loading) return;

    if (!canCreateCourse()) {
      showSnack("❌ غير مسموح لك بإضافة كورسات");
      return;
    }

    if (!validate()) return;

    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser == null) {
      showSnack("سجل الدخول أولاً");
      return;
    }

    setState(() => loading = true);

    try {
      String imageUrl = "images/instructor.png";

      if (imageBytes != null) {
        imageUrl = (await uploadImage() ?? "").trim();
        if (imageUrl.isEmpty) {
          imageUrl = "images/instructor.png";
        }
      }

      final isAdminUser = userData['isAdmin'] == true;
      final courseStatus = isAdminUser ? "approved" : "pending";
      final courseApproved = isAdminUser ? true : false;

      final courseRef = FirebaseService.firestore.collection("courses").doc();

      await courseRef.set({
        "title": title.text.trim(),
        "description": description.text.trim(),
        "categoryId": selectedCategoryId,
        "price": isFree ? 0 : int.tryParse(price.text.trim()) ?? 0,
        "isFree": isFree,
        "image": imageUrl,
        "lessonsCount": 0,
        "rating": 4.5,
        "students": 0,
        "views": 0,
        "instructorId": currentUser.uid,
        "instructorName": userData['name'] ?? "Instructor",
        "status": courseStatus,
        "approved": courseApproved,
        "rejectReason": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore
          .collection("users")
          .doc(currentUser.uid)
          .set({
        "enrolledCourses": FieldValue.arrayUnion([courseRef.id]),
        "unlockedCourses": FieldValue.arrayUnion([courseRef.id]),
      }, SetOptions(merge: true));

      if (!mounted) return;

      showSnack(isAdminUser
          ? "تمت إضافة الكورس بنجاح 🚀"
          : "تم إرسال الكورس للمراجعة 🚀");

      title.clear();
      description.clear();
      price.clear();

      if (mounted) {
        setState(() {
          imageBytes = null;
          imageName = null;
          selectedCategoryId = null;
        });
      }
    } catch (e) {
      debugPrint("$e");

      if (!mounted) return;

      showSnack("خطأ: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        content: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool allowed = canCreateCourse();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            const Text("➕ إضافة كورس", style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: !allowed
          ? const Center(
              child: Text(
                "❌ غير مسموح لك بإضافة كورسات",
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: AppColors.premiumCard,
                      child: imageBytes != null
                          ? Image.memory(imageBytes!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "إضافة صورة للكورس",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    hint: "اسم الكورس",
                    controller: title,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    hint: "وصف الكورس",
                    controller: description,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.firestore
                        .collection("categories")
                        .orderBy("order")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text(
                          "❌ خطأ في تحميل التصنيفات",
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final categories = snapshot.data!.docs;

                      if (categories.isEmpty) {
                        return const Text(
                          "لا توجد تصنيفات",
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      final currentValue = selectedCategoryId != null &&
                              categories.any((c) => c.id == selectedCategoryId)
                          ? selectedCategoryId
                          : null;

                      return DropdownButtonFormField<String>(
                        initialValue: currentValue,
                        dropdownColor: AppColors.black,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "اختار التصنيف",
                        ),
                        items: categories.map((c) {
                          final data = c.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              (data['title'] ?? "").toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() => selectedCategoryId = v);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!isFree)
                    CustomTextField(
                      hint: "السعر",
                      controller: price,
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "كورس مجاني",
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: isFree,
                        onChanged: (v) {
                          setState(() => isFree = v);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.gold),
                        )
                      : CustomButton(
                          text: "🚀 إضافة الكورس",
                          onPressed: addCourse,
                        ),
                ],
              ),
            ),
    );
  }
}
