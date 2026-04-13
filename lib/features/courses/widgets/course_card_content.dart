import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../shared/widgets/press_effect.dart';

class CourseCardContent extends StatefulWidget {
  final String imageUrl;
  final double rating;
  final int totalLessons;
  final String title;
  final double progress;
  final bool hasAccess;
  final bool isPopular;
  final VoidCallback onOpen;

  const CourseCardContent({
    super.key,
    required this.imageUrl,
    required this.rating,
    required this.totalLessons,
    required this.title,
    required this.progress,
    required this.hasAccess,
    required this.isPopular,
    required this.onOpen,
  });

  @override
  State<CourseCardContent> createState() => _CourseCardContentState();
}

class _CourseCardContentState extends State<CourseCardContent>
    with AutomaticKeepAliveClientMixin {
  bool hovered = false;

  @override
  bool get wantKeepAlive => true;

  double _safeDouble(double value, [double fallback = 0]) {
    if (!value.isFinite) return fallback;
    return value;
  }

  double _safeProgress(double value) {
    if (!value.isFinite) return 0.0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double safeProgress = _safeProgress(widget.progress);
    final double safeRating = _safeDouble(widget.rating, 0.0);
    final String cleanImageUrl = widget.imageUrl.trim();

    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        if (!hovered) {
          setState(() => hovered = true);
        }
      },
      onExit: (_) {
        if (!mounted) return;
        if (hovered) {
          setState(() => hovered = false);
        }
      },
      child: PressEffect(
        onTap: () {
          if (!mounted) return;
          widget.onOpen();
        },
        child: RepaintBoundary(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(7),
            transform: Matrix4.identity()
              ..translate(0.0, hovered ? -6.0 : 0.0)
              ..scale(hovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.hasAccess
                    ? AppColors.gold.withValues(alpha: hovered ? 0.7 : 0.5)
                    : Colors.white.withValues(alpha: 0.05),
                width: hovered ? 1.6 : 1.2,
              ),
              boxShadow: [
                ...AppColors.goldShadow,
                BoxShadow(
                  color: widget.hasAccess
                      ? AppColors.gold.withValues(alpha: hovered ? 0.35 : 0.25)
                      : Colors.black.withValues(alpha: 0.45),
                  blurRadius: hovered ? 30 : 26,
                  spreadRadius: hovered ? 2 : 1,
                  offset: Offset(0, hovered ? 16 : 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 262,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RepaintBoundary(
                      child: SizedBox(
                        height: 132,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 400),
                                scale: hovered ? 1.06 : 1,
                                child: _CourseCardImage(
                                  key: ValueKey(cleanImageUrl),
                                  imageUrl: cleanImageUrl,
                                  placeholder: _placeholder,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.95),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.isPopular)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: hovered ? 1.05 : 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "🔥 الأكثر مشاهدة",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!widget.hasAccess)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.lock, color: Colors.red, size: 18),
                              ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      safeRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: AppColors.premiumCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: hovered ? AppColors.gold : AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: hovered ? 13.5 : 13,
                              ),
                              child: Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${widget.totalLessons} درس",
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: safeProgress,
                                minHeight: 6,
                                color: AppColors.gold,
                                backgroundColor: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "أكملت ${(safeProgress * 100).toInt()}%",
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 9,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 35,
                              child: ElevatedButton(
                                style: AppColors.goldButton,
                                onPressed: () {
                                  if (!mounted) return;
                                  widget.onOpen();
                                },
                                child: Text(
                                  safeProgress > 0 ? "استكمال" : "ابدأ الآن",
                                  style: const TextStyle(fontSize: 12),
                                ),
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
    );
  }
}

class _CourseCardImage extends StatelessWidget {
  final String imageUrl;
  final Widget Function() placeholder;

  const _CourseCardImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty || !cleanUrl.startsWith("http")) {
      return placeholder();
    }

    return Image.network(
      cleanUrl,
      key: ValueKey(cleanUrl),
      fit: BoxFit.cover,
      gaplessPlayback: false,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => placeholder(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return placeholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        if (loadingProgress.expectedTotalBytes != null &&
            loadingProgress.expectedTotalBytes! > 0 &&
            loadingProgress.cumulativeBytesLoaded >=
                loadingProgress.expectedTotalBytes!) {
          return child;
        }
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold.withValues(alpha: 0.85),
            ),
          ),
        );
      },
    );
  }
}