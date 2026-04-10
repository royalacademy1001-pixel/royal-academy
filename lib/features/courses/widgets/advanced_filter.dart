import 'package:flutter/material.dart';
import 'package:royal_academy/core/colors.dart';

class AdvancedFilter extends StatelessWidget {
  final String level;
  final String price;
  final String sort;

  final Function(String) onLevel;
  final Function(String) onPrice;
  final Function(String) onSort;

  const AdvancedFilter({
    super.key,
    required this.level,
    required this.price,
    required this.sort,
    required this.onLevel,
    required this.onPrice,
    required this.onSort,
  });

  Widget chip(String title, bool active, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.gold
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 8,
              )
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [

          chip("All", level == "All", () => onLevel(level == "All" ? "All" : "All")),
          chip("Beginner", level == "beginner", () => onLevel(level == "beginner" ? "All" : "beginner")),
          chip("Intermediate", level == "intermediate", () => onLevel(level == "intermediate" ? "All" : "intermediate")),
          chip("Advanced", level == "advanced", () => onLevel(level == "advanced" ? "All" : "advanced")),

          const SizedBox(width: 10),

          chip("Free", price == "free", () => onPrice(price == "free" ? "All" : "free")),
          chip("Paid", price == "paid", () => onPrice(price == "paid" ? "All" : "paid")),

          const SizedBox(width: 10),

          chip("Popular", sort == "popular", () => onSort("popular")),
          chip("Newest", sort == "new", () => onSort("new")),
          chip("Top Rated", sort == "rating", () => onSort("rating")),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: () {
              onLevel("All");
              onPrice("All");
              onSort("popular");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh, color: Colors.red, size: 14),
                  SizedBox(width: 5),
                  Text(
                    "Reset",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}