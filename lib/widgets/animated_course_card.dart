// 🔥 FINAL ANIMATED COURSE CARD (ULTRA UPGRADE - SAFE NO REMOVE)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/colors.dart';
import '../core/firebase_service.dart';

class AnimatedCourseCard extends StatefulWidget {
  final int index;
  final String id;
  final Map<String, dynamic> data;
  final int doneLessons;
  final bool hasAccess;

  final VoidCallback? onTap;

  const AnimatedCourseCard({
    super.key,
    required this.index,
    required this.id,
    required this.data,
    required this.doneLessons,
    required this.hasAccess,
    this.onTap,
  });

  @override
  State<AnimatedCourseCard> createState() =>
      _AnimatedCourseCardState();
}

class _AnimatedCourseCardState extends State<AnimatedCourseCard> {

  bool pressed = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {

    final int totalLessons =
        int.tryParse(widget.data['lessonsCount']?.toString() ?? "0") ?? 0;

    final int safeDone =
        widget.doneLessons < 0 ? 0 : widget.doneLessons;

    final double progress = totalLessons == 0
        ? 0
        : (safeDone / totalLessons).clamp(0.0, 1.0);

    final bool isCompleted = progress >= 1;

    final String image =
        FirebaseService.fixImage((widget.data['image'] ?? "").toString());

    final double rating =
        double.tryParse(widget.data['rating']?.toString() ?? "4.5") ?? 4.5;

    final bool isFree =
        (widget.data['isFree'] ?? false) == true;

    return RepaintBoundary(
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 300 + (widget.index * 60)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {

          final scale = pressed
              ? 0.93
              : hovered
                  ? 1.05
                  : 0.96 + (0.04 * value);

          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },

        child: MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),

          child: InkWell(

            onTap: () {
              if (widget.onTap != null) {
                widget.onTap!();
              }
            },

            onTapDown: (_) => setState(() => pressed = true),
            onTapUp: (_) => setState(() => pressed = false),
            onTapCancel: () => setState(() => pressed = false),

            borderRadius: BorderRadius.circular(22),

            child: Hero(
              tag: "course_${widget.id}",
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 190,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: pressed
                          ? AppColors.gold.withValues(alpha: 0.6)
                          : widget.hasAccess
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.red.withValues(alpha: 0.3),
                      blurRadius: pressed
                          ? 35
                          : hovered
                              ? 25
                              : 15,
                      offset: const Offset(0, 8),
                    ),
                    if (widget.hasAccess) ...AppColors.goldShadow,
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    children: [

                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [

                            Positioned.fill(
                              child: image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (_, __, ___) => _errorImage(),
                                    )
                                  : _placeholder(),
                            ),

                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                      Colors.black,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 8,
                              left: 8,
                              child: _badge(
                                child: Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: _badge(
                                child: Text(
                                  isFree ? "FREE" : "VIP",
                                  style: TextStyle(
                                    color: isFree
                                        ? Colors.green
                                        : AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            if (!widget.hasAccess)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    child: const Center(
                                      child: Text(
                                        "🔒 محتوى مدفوع",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            Center(
                              child: AnimatedScale(
                                scale: pressed ? 0.85 : 1,
                                duration: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isCompleted
                                          ? [Colors.green, Colors.greenAccent]
                                          : const [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFA500),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCompleted
                                            ? Colors.green.withValues(alpha: 0.6)
                                            : AppColors.gold.withValues(alpha: 0.6),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check
                                        : widget.hasAccess
                                            ? Icons.play_arrow
                                            : Icons.lock,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          color: AppColors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                (widget.data['title'] ?? "").toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "$totalLessons درس",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),

                              const SizedBox(height: 6),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  color: isCompleted
                                      ? Colors.green
                                      : AppColors.gold,
                                  backgroundColor: Colors.grey.shade800,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                isCompleted
                                    ? "تم ✔"
                                    : "${(progress * 100).toInt()}%",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.black,
      child: const Center(
        child: Icon(Icons.image_not_supported,
            color: Colors.white38, size: 35),
      ),
    );
  }

  Widget _errorImage() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.refresh, color: Colors.red),
      ),
    );
  }

  Widget _badge({required Widget child}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}