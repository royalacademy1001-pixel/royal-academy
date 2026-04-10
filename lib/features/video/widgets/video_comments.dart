import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../core/colors.dart';

class VideoComments extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const VideoComments({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<VideoComments> createState() => _VideoCommentsState();
}

class _VideoCommentsState extends State<VideoComments> {

  final commentController = TextEditingController();
  DateTime? lastCommentTime;

  Future<void> sendComment() async {
    var user = FirebaseService.auth.currentUser;
    if (user == null) return;

    String text = commentController.text.trim();
    if (text.isEmpty) return;

    if (lastCommentTime != null &&
        DateTime.now().difference(lastCommentTime!).inSeconds < 5) {
      return;
    }

    lastCommentTime = DateTime.now();

    await FirebaseService.firestore.collection(AppConstants.comments).add({
      "lessonId": widget.lessonId,
      "courseId": widget.courseId,
      "userId": user.uid,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    commentController.clear();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: commentController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "اكتب تعليق...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: AppColors.goldButton,
          onPressed: sendComment,
          child: const Text("إرسال"),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.firestore
              .collection(AppConstants.comments)
              .where('lessonId', isEqualTo: widget.lessonId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            var docs = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                var d = docs[i];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    d['text'] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}