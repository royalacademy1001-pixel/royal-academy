import 'package:flutter/material.dart';
import 'core/colors.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingPage({
    super.key,
    required this.onFinish,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController controller = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "title": "Royal Academy",
      "desc": "منصة تعليمية احترافية للعلوم والتكنولوجيا",
      "icon": Icons.school_rounded,
      "features": ["تعلم منظم", "واجهة فخمة", "تجربة سهلة"],
    },
    {
      "title": "تعلم بطريقة منظمة",
      "desc": "فيديوهات، ملفات PDF، اختبارات، ومتابعة تقدمك",
      "icon": Icons.auto_stories_rounded,
      "features": ["فيديوهات", "PDF", "اختبارات", "متابعة"],
    },
    {
      "title": "ابدأ رحلتك الآن",
      "desc": "ادخل على الكورسات وابدأ التعلم من أول لحظة",
      "icon": Icons.rocket_launch_rounded,
      "features": ["كورسات", "تقدمك محفوظ", "ابدأ الآن"],
    },
  ];

  void next() {
    if (currentIndex < pages.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  void skip() {
    widget.onFinish();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Royal Academy",
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: skip,
                        child: const Text(
                          "تخطي",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: pages.length,
                    onPageChanged: (i) {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    itemBuilder: (context, i) {
                      final page = pages[i];
                      final bool active = currentIndex == i;
                      final String title = page["title"] as String;
                      final String desc = page["desc"] as String;
                      final IconData icon = page["icon"] as IconData;
                      final List<String> features = List<String>.from(page["features"] as List);

                      return AnimatedScale(
                        duration: const Duration(milliseconds: 350),
                        scale: active ? 1.0 : 0.96,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                height: 230,
                                width: 230,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gold.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withValues(alpha: 0.12),
                                      blurRadius: 30,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.92, end: active ? 1.0 : 0.92),
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      height: 145,
                                      width: 145,
                                      decoration: BoxDecoration(
                                        color: AppColors.black.withValues(alpha: 0.38),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.gold.withValues(alpha: 0.18),
                                            blurRadius: 28,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        icon,
                                        color: AppColors.gold,
                                        size: 74,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 34),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: active ? 1 : 0.35,
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: active ? 1 : 0.5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    desc,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: features
                                    .map(
                                      (item) => _featureChip(item),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: currentIndex == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentIndex == i ? AppColors.gold : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "اسحب للتنقل بين الصفحات",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: next,
                    child: Text(
                      currentIndex == pages.length - 1 ? "ابدأ الآن" : "التالي",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}