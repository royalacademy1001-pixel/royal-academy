import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_card.dart';

class CoursesList extends StatelessWidget {
  final List<QueryDocumentSnapshot> courses;
  final Function(QueryDocumentSnapshot) onTap;
  final Function(String) hasAccess;

  const CoursesList({
    super.key,
    required this.courses,
    required this.onTap,
    required this.hasAccess,
  });

  @override
  Widget build(BuildContext context) {
    return courses.isEmpty
        ? const Center(
            child: Text(
              "لا يوجد بيانات",
              style: TextStyle(color: Colors.grey),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;

              if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }
              if (constraints.maxWidth > 1000) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                itemCount: courses.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 1.6 : 1.1,
                ),
                itemBuilder: (context, index) {
                  final c = courses[index];
                  final data = (c.data() as Map<String, dynamic>? ?? {});

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 40)),
                    tween: Tween(begin: 0.92, end: 1),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 40),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0, 1),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => onTap(c),
                      child: CourseCard(
                        id: c.id,
                        data: data,
                        doneLessons: 0,
                        hasAccess: hasAccess(c.id),
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}