import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CourseHeader extends StatelessWidget {
  final String title;
  final String image;
  final int views;
  final int purchases;
  final Widget progressWidget;
  final Widget? resumeButton;

  const CourseHeader({
    super.key,
    required this.title,
    required this.image,
    required this.views,
    required this.purchases,
    required this.progressWidget,
    this.resumeButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: image.isEmpty
              ? Container(color: Colors.black)
              : Image.network(image, fit: BoxFit.cover),
        ),
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          left: 15,
          right: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text("👁 $views",
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 15),
                  Text("💰 $purchases",
                      style: const TextStyle(color: AppColors.gold)),
                ],
              ),
              const SizedBox(height: 10),
              progressWidget,
              if (resumeButton != null) ...[
                const SizedBox(height: 10),
                resumeButton!,
              ]
            ],
          ),
        ),
      ],
    );
  }
}