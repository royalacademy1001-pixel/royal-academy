import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class NewsAdminPage extends StatelessWidget {
  const NewsAdminPage({super.key});

  Future deleteNews(String id, String imageUrl) async {
    if (imageUrl.toString().isNotEmpty) {
      try {
        await FirebaseService.storage.refFromURL(imageUrl).delete();
      } catch (_) {}
    }

    await FirebaseService.firestore.collection("news").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("📰 إدارة الأخبار",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("news")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("لا يوجد أخبار",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? "";
              final image = data['image'] ?? "";

              return Card(
                color: AppColors.black,
                margin: const EdgeInsets.all(10),
                child: ListTile(

                  leading: image.toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, color: Colors.white),

                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {

                      await deleteNews(doc.id, image);

                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}