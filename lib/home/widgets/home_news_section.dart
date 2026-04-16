import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class HomeNewsSection extends StatelessWidget {
  const HomeNewsSection({super.key});

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedNews = [];
  static DateTime? _lastFetchTime;

  void _showNewsDetails(BuildContext context, String title, String image) {
    if (!context.mounted) return;

    final String safeTitle = title.trim().isEmpty ? "" : title.trim();
    final String safeImage = image.trim();

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: AppColors.black.withValues(alpha: 0.85),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (safeImage.isNotEmpty && safeImage.startsWith("http"))
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CachedNetworkImage(
                    imageUrl: safeImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              if (safeImage.isEmpty || !safeImage.startsWith("http"))
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  safeTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.newspaper_rounded,
                color: AppColors.gold, size: 18),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final useCache = _cachedNews.isNotEmpty &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < 60;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: useCache
          ? null
          : FirebaseService.firestore
              .collection("news")
              .orderBy("createdAt", descending: true)
              .limit(5)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = useCache
            ? _cachedNews
            : (snapshot.hasData && snapshot.data != null
                ? snapshot.data!.docs
                : <QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        if (!useCache &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (docs.isEmpty) {
          return const SizedBox();
        }

        if (!useCache && docs.isNotEmpty) {
          _cachedNews = docs;
          _lastFetchTime = DateTime.now();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseService.firestore
              .collection("app_settings")
              .doc("home_sections")
              .get(),
          builder: (context, configSnap) {
            if (configSnap.hasData &&
                configSnap.data != null &&
                configSnap.data!.data() != null) {
              final config = configSnap.data!.data()!;
              final sections = config['sections'];

              if (sections is List) {
                final found = sections.where((e) {
                  if (e is Map<String, dynamic>) {
                    return e['id'] == "news";
                  }
                  return false;
                }).toList();

                if (found.isNotEmpty) {
                  final item = found.first as Map<String, dynamic>;
                  if ((item['enabled'] ?? true) == false) {
                    return const SizedBox();
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title("📰 آخر الأخبار"),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final image = FirebaseService.fixImage(
                        (data['image'] ?? "").toString(),
                      ).trim();
                      final title = (data['title'] ?? "").toString().trim();

                      return GestureDetector(
                        onTap: () {
                          if (!context.mounted) return;
                          _showNewsDetails(context, title, image);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 285,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            color: const Color(0xFF151515),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: image.isEmpty || !image.startsWith("http")
                                      ? Container(color: const Color(0xFF1A1A1A))
                                      : CachedNetworkImage(
                                          imageUrl: image,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: const Color(0xFF1A1A1A),
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: const Color(0xFF1A1A1A),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.9),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 15,
                                  left: 15,
                                  bottom: 15,
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}