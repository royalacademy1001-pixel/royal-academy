// 🔥 FINAL ULTRA COURSE PROGRESS (PRO MAX++ ULTRA UPGRADE SAFE)

import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CourseProgress extends StatefulWidget {
  final double progress;
  final int done;
  final int total;

  const CourseProgress({
    super.key,
    required this.progress,
    required this.done,
    required this.total,
  });

  @override
  State<CourseProgress> createState() => _CourseProgressState();
}

class _CourseProgressState extends State<CourseProgress> {

  double lastValue = 0;

  @override
  void didUpdateWidget(covariant CourseProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    lastValue = oldWidget.progress.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {

    /// ================= SAFE VALUES =================
    double safeProgress =
        widget.progress.isNaN || widget.progress.isInfinite
            ? 0
            : widget.progress.clamp(0, 1);

    if (safeProgress < lastValue) {
      lastValue = safeProgress;
    }

    int percent = (safeProgress * 100).toInt();

    int safeTotal = widget.total <= 0 ? 0 : widget.total;
    int safeDone =
        widget.done > safeTotal ? safeTotal : widget.done;

    /// ================= XP =================
    int xp = safeDone * 10;

    /// ================= LEVEL =================
    int level = (percent ~/ 25) + 1;
    if (level > 5) level = 5;

    /// ================= NEXT LEVEL =================
    int nextLevelTarget = (level * 25);
    int remainingToNext =
        nextLevelTarget > 100 ? 0 : (nextLevelTarget - percent);

    bool completed = safeProgress >= 1.0 && safeTotal > 0;

    /// ================= COLORS =================
    Color progressColor;
    if (completed) {
      progressColor = Colors.green;
    } else if (percent > 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.gold;
    }

    /// ================= MOTIVATION =================
    String motivation;
    if (completed) {
      motivation = "🔥 ممتاز! خلصت الكورس";
    } else if (percent > 85) {
      motivation = "🔥 قربت جدًا من النهاية!";
    } else if (percent > 70) {
      motivation = "💪 قربت تخلص!";
    } else if (percent > 30) {
      motivation = "🚀 كمل أنت ماشي صح";
    } else {
      motivation = "📚 ابدأ رحلتك";
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📊 تقدمك في الكورس",
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$percent%",
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// ================= MOTIVATION =================
          Text(
            motivation,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          /// ================= PROGRESS BAR (ULTRA) =================
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
              tween: Tween(begin: lastValue, end: safeProgress),
              builder: (context, value, _) {

                return Stack(
                  children: [

                    /// BACK
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    /// FRONT GRADIENT
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              progressColor.withValues(alpha: 0.7),
                              progressColor,
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// GLOW
                    if (value > 0.85)
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 0.7),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          /// ================= DETAILS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "📚 $safeDone / $safeTotal درس",
                style: const TextStyle(color: AppColors.grey),
              ),
              if (completed)
                const Text(
                  "🎉 مكتمل",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  safeTotal == 0
                      ? "لا يوجد دروس"
                      : "باقي ${safeTotal - safeDone}",
                  style: const TextStyle(color: Colors.orange),
                ),
            ],
          ),

          const SizedBox(height: 12),

          /// ================= NEXT LEVEL =================
          if (!completed && remainingToNext > 0)
            Text(
              "📈 باقي $remainingToNext% للمستوى التالي",
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
              ),
            ),

          const SizedBox(height: 12),

          /// ================= XP + LEVEL =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _badge("⚡ XP: $xp", Colors.yellow),

              _badge(
                "🏆 Level $level",
                level >= 4
                    ? Colors.green
                    : level >= 2
                        ? Colors.orange
                        : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}