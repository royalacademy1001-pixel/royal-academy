import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/utils.dart';
import '../shared/widgets/custom_button.dart';
import '../shared/widgets/custom_textfield.dart';
import '/shared/widgets/loading_widget.dart';

class AddLessonPage extends StatefulWidget {
  final String? courseId;

  const AddLessonPage({
    super.key,
    this.courseId,
  });

  @override
  State<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final titleController = TextEditingController();
  final linkController = TextEditingController();

  String searchText = "";
  String? selectedCourseId;
  String selectedCourseName = "";

  String selectedType = "video";

  int nextOrder = 1;
  bool loading = false;
  bool loadingUser = true;

  Uint8List? selectedBytes;
  String selectedFileName = "";

  List<String> teachingCourses = [];

  bool uploadingFile = false;
  double uploadProgress = 0;
  String uploadStatus = "";

  StreamSubscription<TaskSnapshot>? uploadSubscription;

  bool _uploadLock = false;

  @override
  void initState() {
    super.initState();

    loadInstructorCourses();

    if (widget.courseId != null) {
      selectedCourseId = widget.courseId;
      loadCourseName();
      loadNextOrder();
    }
  }

  Future<void> loadInstructorCourses() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            loadingUser = false;
          });
        }
        return;
      }

      final doc = await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .get();

      final rawCourses = doc.data()?['teachingCourses'];
      if (rawCourses is List) {
        teachingCourses = rawCourses.map((e) => e.toString()).toList();
      } else {
        teachingCourses = [];
      }

      if (mounted) {
        setState(() {
          loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loadingUser = false;
        });
      }
    }
  }

  Stream<QuerySnapshot> getCourses() {
    return FirebaseService.firestore
        .collection(AppConstants.courses)
        .snapshots();
  }

  Future<void> loadCourseName() async {
    try {
      final doc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .get();

      selectedCourseName = (doc.data()?['title'] ?? "").toString();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> loadNextOrder() async {
    try {
      final lastLesson = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .collection(AppConstants.lessons)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (lastLesson.docs.isEmpty) {
        nextOrder = 1;
      } else {
        final rawOrder = lastLesson.docs.first.data()['order'];

        final int lastOrder =
            rawOrder is int ? rawOrder : int.tryParse(rawOrder.toString()) ?? 0;

        nextOrder = lastOrder + 1;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> selectCourse(String id, String title) async {
    selectedCourseId = id;
    selectedCourseName = title;

    try {
      final lastLesson = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(id)
          .collection(AppConstants.lessons)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (lastLesson.docs.isEmpty) {
        nextOrder = 1;
      } else {
        final rawOrder = lastLesson.docs.first.data()['order'];

        final int lastOrder =
            rawOrder is int ? rawOrder : int.tryParse(rawOrder.toString()) ?? 0;

        nextOrder = lastOrder + 1;
      }
    } catch (_) {
      nextOrder = 1;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickFile() async {
    if (_uploadLock) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
      );

      if (result == null) return;

      selectedBytes = result.files.single.bytes;
      selectedFileName = result.files.single.name;

      if (selectedBytes == null) {
        showSnack(context, "تعذر قراءة الملف ❌", color: Colors.red);
        return;
      }

      final name = selectedFileName.toLowerCase();

      if (name.endsWith(".pdf")) {
        selectedType = "pdf";
      } else if (name.endsWith(".mp3") || name.endsWith(".wav")) {
        selectedType = "audio";
      } else {
        selectedType = "video";
      }

      uploadProgress = 0;
      uploadStatus = "";

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      showSnack(context, "فشل اختيار الملف ❌", color: Colors.red);
    }
  }

  String _contentTypeFromName(String? name) {
    final lower = (name ?? "").toLowerCase();

    if (lower.endsWith(".pdf")) return "application/pdf";
    if (lower.endsWith(".mp3")) return "audio/mpeg";
    if (lower.endsWith(".wav")) return "audio/wav";
    if (lower.endsWith(".mov")) return "video/quicktime";
    if (lower.endsWith(".avi")) return "video/x-msvideo";
    if (lower.endsWith(".webm")) return "video/webm";
    if (lower.endsWith(".mp4")) return "video/mp4";

    return "application/octet-stream";
  }

  Widget _buildUploadProgress() {
    if (!uploadingFile && uploadProgress <= 0 && uploadStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeValue = uploadProgress.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uploadStatus.isEmpty ? "جاري الرفع..." : uploadStatus,
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
              value:
                  uploadingFile ? safeValue : (safeValue >= 1 ? 1 : safeValue),
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

  Future<String?> uploadFile() async {
    if (_uploadLock) return null;
    _uploadLock = true;

    try {
      if (selectedBytes == null) return null;
      if (selectedCourseId == null) return null;

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_$selectedFileName";

      final ref = FirebaseService.storage
          .ref()
          .child("courses/$selectedCourseId/$fileName");

      final metadata = SettableMetadata(
        contentType: _contentTypeFromName(selectedFileName),
      );

      if (mounted) {
        setState(() {
          uploadingFile = true;
          uploadProgress = 0.01;
          uploadStatus = "بدء الرفع...";
        });
      }

      final uploadTask = ref.putData(selectedBytes!, metadata);

      await uploadSubscription?.cancel();
      uploadSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) return;

        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        double progress = total <= 0 ? 0.01 : transferred / total;

        if (progress == 0) progress = 0.01;

        setState(() {
          uploadProgress = progress.clamp(0.01, 1.0).toDouble();
          uploadStatus = uploadProgress >= 1
              ? "انتهى الرفع"
              : "جاري الرفع ${(uploadProgress * 100).toInt()}%";
        });
      });

      await uploadTask;

      final url = await ref.getDownloadURL();
      if (url.isEmpty) return null;
      if (!url.startsWith("http")) return null;

      if (mounted) {
        setState(() {
          uploadingFile = false;
          uploadProgress = 1;
          uploadStatus = "انتهى الرفع";
        });
      }

      return url;
    } catch (e) {
      if (mounted) {
        setState(() {
          uploadingFile = false;
          uploadStatus = e.toString();
        });
      }
      return null;
    } finally {
      await uploadSubscription?.cancel();
      uploadSubscription = null;
      _uploadLock = false;

      if (mounted && uploadingFile) {
        setState(() => uploadingFile = false);
      }
    }
  }

  bool canAddLesson() {
    return !loading && !uploadingFile && !_uploadLock;
  }

  Future<void> addLesson() async {
    if (!canAddLesson()) return;

    if (selectedCourseId == null) {
      showSnack(context, "اختار كورس ❗", color: Colors.red);
      return;
    }

    final lessonTitle = titleController.text.trim();

    if (lessonTitle.isEmpty) {
      showSnack(context, "اكتب عنوان ❗", color: Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      String finalUrl = "";
      final name = selectedFileName.toLowerCase();

      if (selectedBytes != null) {
        if (selectedType == "pdf" && !name.endsWith(".pdf")) {
          showSnack(context, "ارفع ملف PDF فقط ❌", color: Colors.red);
          setState(() => loading = false);
          return;
        }

        if (selectedType == "audio" &&
            !(name.endsWith(".mp3") || name.endsWith(".wav"))) {
          showSnack(context, "ارفع ملف صوت فقط ❌", color: Colors.red);
          setState(() => loading = false);
          return;
        }

        if (selectedType == "video" &&
            !(name.endsWith(".mp4") ||
                name.endsWith(".mov") ||
                name.endsWith(".avi") ||
                name.endsWith(".webm"))) {
          showSnack(context, "ارفع فيديو صحيح ❌", color: Colors.red);
          setState(() => loading = false);
          return;
        }

        final uploaded = await uploadFile();
        if (!mounted) return;

        if (uploaded == null) {
          showSnack(context, "فشل رفع الملف ❌", color: Colors.red);
          setState(() => loading = false);
          return;
        }

        finalUrl = uploaded;
      } else {
        finalUrl = linkController.text.trim();
      }

      if (finalUrl.isEmpty) {
        showSnack(context, "أدخل رابط أو ملف ❗", color: Colors.red);
        setState(() => loading = false);
        return;
      }

      final courseDoc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(selectedCourseId)
          .get();

      final courseData = courseDoc.data() ?? {};

      await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(selectedCourseId)
          .collection(AppConstants.lessons)
          .add({
        "title": lessonTitle,
        "type": selectedType,
        "contentUrl": finalUrl,
        "order": nextOrder,
        "isFree": courseData['isFree'] == true ? true : false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(selectedCourseId)
          .update({
        "lessonsCount": FieldValue.increment(1),
      });

      if (!mounted) return;

      showSnack(context, "تمت الإضافة ✅");

      titleController.clear();
      linkController.clear();

      setState(() {
        selectedBytes = null;
        selectedFileName = "";
        nextOrder++;
        uploadProgress = 0;
        uploadStatus = "";
      });
    } catch (_) {
      if (!mounted) return;
      showSnack(context, "خطأ ❌", color: Colors.red);
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  void dispose() {
    uploadSubscription?.cancel();
    titleController.dispose();
    linkController.dispose();
    super.dispose();
  }

  Widget _buildCourseSelector() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (val) => setState(() => searchText = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "🔍 ابحث عن كورس",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppColors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: getCourses(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingWidget();
              }

              final courses = snapshot.data!.docs;

              final filtered = courses.where((c) {
                final data = c.data() as Map<String, dynamic>;
                final title = (data['title'] ?? "").toString().toLowerCase();

                final allowed = teachingCourses.isEmpty
                    ? true
                    : teachingCourses.contains(c.id);

                return allowed && title.contains(searchText.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    "لا توجد كورسات متاحة",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final data = c.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(
                      (data['title'] ?? "").toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: selectedCourseId == c.id
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () =>
                        selectCourse(c.id, (data['title'] ?? "").toString()),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLessonForm() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📚 $selectedCourseName",
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "📌 ترتيب: $nextOrder",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            hint: "عنوان",
            controller: titleController,
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedType,
            dropdownColor: Colors.black,
            items: const [
              DropdownMenuItem(value: "video", child: Text("🎥 فيديو")),
              DropdownMenuItem(value: "pdf", child: Text("📄 PDF")),
              DropdownMenuItem(value: "audio", child: Text("🎧 صوت")),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() => selectedType = val);
            },
          ),
          const SizedBox(height: 10),
          CustomTextField(
            hint: "رابط (اختياري)",
            controller: linkController,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: uploadingFile ? null : pickFile,
            child: const Text("📂 اختيار ملف"),
          ),
          const SizedBox(height: 10),
          if (selectedFileName.isNotEmpty)
            Text(
              selectedFileName,
              style: const TextStyle(color: Colors.white70),
            ),
          if (selectedBytes != null || selectedFileName.isNotEmpty)
            const Text(
              "تم اختيار ملف ✔",
              style: TextStyle(color: Colors.green),
            ),
          const SizedBox(height: 12),
          _buildUploadProgress(),
          const SizedBox(height: 15),
          loading
              ? const LoadingWidget()
              : CustomButton(
                  text: "➕ إضافة",
                  onPressed: addLesson,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "➕ إضافة محتوى",
          style: TextStyle(color: AppColors.gold),
        ),
        backgroundColor: AppColors.black,
      ),
      body: Column(
        children: [
          if (widget.courseId == null && selectedCourseId == null)
            Expanded(
              child: _buildCourseSelector(),
            ),
          if (selectedCourseId != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: _buildLessonForm(),
              ),
            ),
        ],
      ),
    );
  }
}
