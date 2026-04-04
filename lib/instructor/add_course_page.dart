// 🔥 ADD COURSE (FINAL STABLE VERSION SAFE)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/colors.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();

  File? imageFile;
  File? videoFile;
  File? pdfFile;

  bool loading = false;

  /// 📷 PICK IMAGE
  Future pickImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery);

      if (picked != null) {
        imageFile = File(picked.path);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  /// 🎥 PICK VIDEO
  Future pickVideo() async {
    try {
      var res = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (res != null && res.files.single.path != null) {
        videoFile = File(res.files.single.path!);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  /// 📄 PICK PDF
  Future pickPDF() async {
    try {
      var res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (res != null && res.files.single.path != null) {
        pdfFile = File(res.files.single.path!);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  /// 🔥 UPLOAD FILE
  Future<String> uploadFile(File file, String folder) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}";
      final ref = FirebaseStorage.instance
          .ref("$folder/$fileName");

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return "";
    }
  }

  /// 🚀 SUBMIT
  Future submit() async {

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    if (titleController.text.trim().isEmpty) {
      show("اكتب اسم الكورس");
      return;
    }

    if (mounted) setState(() => loading = true);

    try {

      String imageUrl = "";
      String videoUrl = "";
      String pdfUrl = "";

      /// 🔥 UPLOADS
      if (imageFile != null) {
        imageUrl = await uploadFile(
            imageFile!, "courses/images");
      }

      if (videoFile != null) {
        videoUrl = await uploadFile(
            videoFile!, "courses/videos");
      }

      if (pdfFile != null) {
        pdfUrl = await uploadFile(
            pdfFile!, "courses/pdfs");
      }

      /// 🔥 SAVE COURSE
      await FirebaseService.firestore
          .collection("courses")
          .add({
        "title": titleController.text.trim(),
        "description": descController.text.trim(),
        "price": int.tryParse(priceController.text) ?? 0,
        "image": imageUrl,
        "video": videoUrl,
        "pdf": pdfUrl,
        "instructorId": user.uid,
        "approved": false,
        "students": 0,
        "views": 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      show("تم رفع الكورس 🎉");

      if (mounted) Navigator.pop(context);

    } catch (e) {
      show("خطأ ❌");
    }

    if (mounted) setState(() => loading = false);
  }

  void show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("➕ إضافة كورس",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "اسم الكورس",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "الوصف",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "السعر",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("📷 اختيار صورة"),
            ),

            ElevatedButton(
              onPressed: pickVideo,
              child: const Text("🎥 رفع فيديو"),
            ),

            ElevatedButton(
              onPressed: pickPDF,
              child: const Text("📄 رفع PDF"),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: AppColors.goldButton,
                    onPressed: submit,
                    child: const Text("🚀 رفع الكورس"),
                  ),
          ],
        ),
      ),
    );
  }
}