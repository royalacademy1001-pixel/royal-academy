// 🔥 IMPORTS
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        webImage = bytes;
        imageFile = null;
      });
    } else {
      setState(() {
        imageFile = File(picked.path);
        webImage = null;
      });
    }
  }

  Future<String> uploadImage() async {
    final ref = FirebaseService.storage
        .ref()
        .child("news/${DateTime.now().millisecondsSinceEpoch}.jpg");

    if (kIsWeb && webImage != null) {
      await ref.putData(webImage!);
    } else if (imageFile != null) {
      await ref.putFile(imageFile!);
    } else {
      return "";
    }

    return await ref.getDownloadURL();
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
              onTap: pickImage,
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppColors.goldButton,
                onPressed: loading ? null : addNews,
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