import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/colors.dart';
import '../shared/widgets/custom_button.dart';
import '../shared/widgets/custom_textfield.dart';

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

  bool uploadingImage = false;
  double uploadProgress = 0;
  String uploadStatus = "";

  StreamSubscription<TaskSnapshot>? _uploadSubscription;

  bool _uploadingLock = false;

  Future<void> loadUser() async {
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

  bool _canShowUploadBar() {
    return uploadingImage || uploadProgress > 0 || uploadStatus.isNotEmpty;
  }

  Widget _buildUploadProgress() {
    if (!_canShowUploadBar()) {
      return const SizedBox.shrink();
    }

    final double safeValue = uploadProgress.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uploadStatus.isEmpty ? "جاري رفع الصورة..." : uploadStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: uploadingImage ? safeValue : (safeValue >= 1 ? 1 : safeValue),
              minHeight: 8,
              color: AppColors.gold,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            uploadProgress >= 1 ? "100%" : "${(safeValue * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    if (_uploadingLock) return;

    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      imageName = picked.name;
      imageBytes = await picked.readAsBytes();

      if (mounted) {
        setState(() {
          uploadProgress = 0;
          uploadStatus = "";
        });
      }
    } catch (e) {
      showSnack("فشل اختيار الصورة ❌");
    }
  }

  Future<String?> uploadImage() async {
    if (_uploadingLock) return null;
    _uploadingLock = true;

    try {
      final bytes = imageBytes;
      if (bytes == null || bytes.isEmpty) return null;

      final currentUser = FirebaseService.auth.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.reload();
          await currentUser.getIdToken(true);
        } catch (_) {}
      }

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

      if (mounted) {
        setState(() {
          uploadingImage = true;
          uploadProgress = 0;
          uploadStatus = "جاري رفع الصورة...";
        });
      }

      final uploadTask = ref.putData(bytes, metadata);

      await _uploadSubscription?.cancel();
      _uploadSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) return;

        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;

        final progress = total <= 0 ? 0.0 : transferred / total;

        setState(() {
          uploadProgress = progress.clamp(0.0, 1.0).toDouble();
          uploadStatus = uploadProgress >= 1
              ? "انتهى الرفع"
              : "جاري رفع الصورة ${(uploadProgress * 100).toInt()}%";
        });
      });

      await uploadTask.whenComplete(() {});

      final url = await ref.getDownloadURL();
      if (url.isEmpty || !url.startsWith("http")) return null;

      if (mounted) {
        setState(() {
          uploadingImage = false;
          uploadProgress = 1;
          uploadStatus = "انتهى الرفع";
        });
      }

      return url;
    } catch (e) {
      debugPrint("🔥 Upload Error: $e");

      if (mounted) {
        setState(() {
          uploadingImage = false;
          uploadStatus = "فشل رفع الصورة";
        });
      }

      return null;
    } finally {
      await _uploadSubscription?.cancel();
      _uploadSubscription = null;
      _uploadingLock = false;

      if (mounted && uploadingImage) {
        setState(() => uploadingImage = false);
      }
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: uploadingImage ? null : pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: AppColors.premiumCard,
            child: imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
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
        const SizedBox(height: 12),
        _buildUploadProgress(),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
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
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePicker(),
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
        _buildCategoryDropdown(),
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
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : CustomButton(
                text: "🚀 إضافة الكورس",
                onPressed: addCourse,
              ),
      ],
    );
  }

  Future<void> addCourse() async {
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
      String imageUrl = "";

      if (imageBytes != null) {
        imageUrl = (await uploadImage() ?? "").trim();
        if (imageUrl.isEmpty) {
          imageUrl = "";
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
          uploadProgress = 0;
          uploadStatus = "";
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
    _uploadSubscription?.cancel();
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
              child: _buildForm(),
            ),
    );
  }
}