// 🔥 IMPORTS
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_service.dart';
import '../core/colors.dart';

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({super.key});

  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {

  final TextEditingController titleController = TextEditingController();

  File? imageFile;
  Uint8List? webImage;
  bool loading = false;

  bool uploading = false;
  double uploadProgress = 0;
  String uploadStatus = "";

  StreamSubscription<TaskSnapshot>? uploadSub;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        webImage = bytes;
        imageFile = null;
        uploadProgress = 0;
        uploadStatus = "";
      });
    } else {
      setState(() {
        imageFile = File(picked.path);
        webImage = null;
        uploadProgress = 0;
        uploadStatus = "";
      });
    }
  }

  Widget buildProgress() {
    if (!uploading && uploadProgress <= 0 && uploadStatus.isEmpty) {
      return const SizedBox();
    }

    double value = uploadProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uploadStatus.isEmpty ? "جاري الرفع..." : uploadStatus,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: uploading ? value : (value >= 1 ? 1 : value),
          color: AppColors.gold,
          backgroundColor: Colors.white12,
        ),
        const SizedBox(height: 6),
        Text(
          uploadProgress >= 1 ? "100%" : "${(value * 100).toInt()}%",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Future<String> uploadImage() async {

    final ref = FirebaseService.storage
        .ref()
        .child("news/${DateTime.now().millisecondsSinceEpoch}.jpg");

    setState(() {
      uploading = true;
      uploadProgress = 0;
      uploadStatus = "جاري رفع الصورة...";
    });

    UploadTask task;

    if (kIsWeb && webImage != null) {
      task = ref.putData(webImage!);
    } else if (imageFile != null) {
      task = ref.putFile(imageFile!);
    } else {
      setState(() {
        uploading = false;
      });
      return "";
    }

    await uploadSub?.cancel();
    uploadSub = task.snapshotEvents.listen((snapshot) {
      if (!mounted) return;

      final total = snapshot.totalBytes;
      final transferred = snapshot.bytesTransferred;

      final progress = total == 0 ? 0.0 : transferred / total;

      setState(() {
        uploadProgress = progress;
        uploadStatus = uploadProgress >= 1
            ? "انتهى الرفع"
            : "جاري الرفع ${(uploadProgress * 100).toInt()}%";
      });
    });

    await task;

    final url = await ref.getDownloadURL();

    setState(() {
      uploading = false;
      uploadProgress = 1;
      uploadStatus = "انتهى الرفع";
    });

    return url;
  }

  Future addNews() async {

    if (titleController.text.trim().isEmpty) return;

    setState(() => loading = true);

    String imageUrl = await uploadImage();

    await FirebaseService.firestore.collection("news").add({
      "title": titleController.text.trim(),
      "image": imageUrl,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    uploadSub?.cancel();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("📰 إضافة خبر",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "عنوان الخبر",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: uploading ? null : pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: (imageFile == null && webImage == null)
                    ? const Icon(Icons.add_a_photo, color: Colors.white)
                    : (kIsWeb
                        ? Image.memory(webImage!, fit: BoxFit.cover)
                        : Image.file(imageFile!, fit: BoxFit.cover)),
              ),
            ),

            const SizedBox(height: 15),

            buildProgress(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppColors.goldButton,
                onPressed: loading || uploading ? null : addNews,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("نشر الخبر"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}