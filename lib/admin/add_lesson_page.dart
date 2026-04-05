// 🔥 FINAL ADD LESSON PAGE (ULTRA PRO MAX++ FINAL SAFE UPGRADED FIXED)

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

// 🔥 Core
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/utils.dart';

// 🔥 Widgets
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_widget.dart';

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

  File? selectedFile;
  Uint8List? selectedBytes;
  String selectedFileName = "";

  List teachingCourses = [];

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

  Future loadInstructorCourses() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      var doc = await FirebaseService.firestore
          .collection("users")
          .doc(user.uid)
          .get();

      teachingCourses = List<String>.from(doc.data()?['teachingCourses'] ?? []);
      setState(() {});
    } catch (_) {}
  }

  Stream<QuerySnapshot> getCourses() {
    return FirebaseService.firestore
        .collection(AppConstants.courses)
        .snapshots();
  }

  Future loadCourseName() async {
    try {
      var doc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .get();

      selectedCourseName = doc.data()?['title'] ?? "";
      setState(() {});
    } catch (_) {}
  }

  Future loadNextOrder() async {
    try {
      var lastLesson = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .collection(AppConstants.lessons)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (lastLesson.docs.isEmpty) {
        nextOrder = 1;
      } else {
        var rawOrder = lastLesson.docs.first.data()['order'];

        int lastOrder = rawOrder is int
            ? rawOrder
            : int.tryParse(rawOrder.toString()) ?? 0;

        nextOrder = lastOrder + 1;
      }

      setState(() {});
    } catch (_) {}
  }

  Future selectCourse(String id, String title) async {

    selectedCourseId = id;
    selectedCourseName = title;

    try {
      var lastLesson = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(id)
          .collection(AppConstants.lessons)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (lastLesson.docs.isEmpty) {
        nextOrder = 1;
      } else {
        var rawOrder = lastLesson.docs.first.data()['order'];

        int lastOrder = rawOrder is int
            ? rawOrder
            : int.tryParse(rawOrder.toString()) ?? 0;

        nextOrder = lastOrder + 1;
      }

    } catch (_) {
      nextOrder = 1;
    }

    setState(() {});
  }

  Future pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
      );

      if (result != null) {

        selectedBytes = result.files.single.bytes;
        selectedFileName = result.files.single.name;

        if (selectedBytes == null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
        }

        String name = selectedFileName.toLowerCase();

        if (name.endsWith(".pdf")) {
          selectedType = "pdf";
        } else if (name.endsWith(".mp3") || name.endsWith(".wav")) {
          selectedType = "audio";
        } else {
          selectedType = "video";
        }

        setState(() {});
      }

    } catch (_) {
      showSnack(context, "فشل اختيار الملف ❌");
    }
  }

  Future<String?> uploadFile() async {
    try {
      if (selectedBytes == null && selectedFile == null) return null;

      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_$selectedFileName";

      final ref = FirebaseService.storage
          .ref()
          .child("courses/$selectedCourseId/$fileName");

      if (selectedBytes != null) {
        await ref.putData(selectedBytes!);
      } else {
        await ref.putFile(selectedFile!);
      }

      return await ref.getDownloadURL();

    } catch (_) {
      return null;
    }
  }

  Future addLesson() async {

    if (loading) return;

    if (selectedCourseId == null) {
      showSnack(context, "اختار كورس ❗", color: Colors.red);
      return;
    }

    String title = titleController.text.trim();

    if (title.isEmpty) {
      showSnack(context, "اكتب عنوان ❗", color: Colors.red);
      return;
    }

    setState(() => loading = true);

    try {

      String finalUrl = "";

      String name = selectedFileName.toLowerCase();

if (selectedBytes != null || selectedFile != null) {

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
        name.endsWith(".avi"))) {
    showSnack(context, "ارفع فيديو صحيح ❌", color: Colors.red);
    setState(() => loading = false);
    return;
  }

  String? uploaded = await uploadFile();

  if (uploaded == null) {
    showSnack(context, "فشل رفع الملف ❌");
    setState(() => loading = false);
    return;
  }

  finalUrl = uploaded;

      } else {
        finalUrl = linkController.text.trim();
      }

      if (finalUrl.isEmpty) {
        showSnack(context, "أدخل رابط أو ملف ❗");
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
        "title": title,
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

      showSnack(context, "تمت الإضافة ✅");

      titleController.clear();
      linkController.clear();

      setState(() {
        selectedFile = null;
        selectedBytes = null;
        selectedFileName = "";
        nextOrder++;
      });

    } catch (_) {
      showSnack(context, "خطأ ❌", color: Colors.red);
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    titleController.dispose();
    linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("➕ إضافة محتوى",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          if (widget.courseId == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (val) =>
                    setState(() => searchText = val),
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

          if (widget.courseId == null)
            Expanded(
              child: StreamBuilder(
                stream: getCourses(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const LoadingWidget();
                  }

                  var courses = snapshot.data!.docs;

                  var filtered = courses.where((c) {
                    var data = c.data() as Map<String, dynamic>;
                    String title =
                        (data['title'] ?? "").toLowerCase();

                    bool allowed = teachingCourses.isEmpty
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

                      var c = filtered[i];
                      var data = c.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text(
                          data['title'] ?? "",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: selectedCourseId == c.id
                            ? const Icon(Icons.check,
                                color: Colors.green)
                            : null,
                        onTap: () =>
                            selectCourse(c.id, data['title']),
                      );
                    },
                  );
                },
              ),
            ),

          if (selectedCourseId != null)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: AppColors.premiumCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("📚 $selectedCourseName",
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      )),

                  Text("📌 ترتيب: $nextOrder",
                      style: const TextStyle(color: Colors.grey)),

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
                    onChanged: (val) =>
                        setState(() => selectedType = val!),
                  ),

                  const SizedBox(height: 10),

                  CustomTextField(
                    hint: "رابط (اختياري)",
                    controller: linkController,
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: pickFile,
                    child: const Text("📂 اختيار ملف"),
                  ),

                  if (selectedBytes != null || selectedFile != null)
                    const Text(
                      "تم اختيار ملف ✔",
                      style: TextStyle(color: Colors.green),
                    ),

                  const SizedBox(height: 15),

                  loading
                      ? const LoadingWidget()
                      : CustomButton(
                          text: "➕ إضافة",
                          onPressed: addLesson,
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}