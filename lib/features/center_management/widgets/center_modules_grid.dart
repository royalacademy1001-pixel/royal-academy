import 'package:flutter/material.dart';
import '../models/admin_module.dart';
import 'center_module_card.dart';

class CenterModulesGrid extends StatelessWidget {
  final List<AdminModule> modules;

  final bool isAdmin;
  final bool isVIP;
  final bool isInstructor;

  final String search;

  const CenterModulesGrid({
    super.key,
    required this.modules,
    required this.isAdmin,
    required this.isVIP,
    required this.isInstructor,
    required this.search,
  });

  List<AdminModule> _filterModules() {
    final q = search.toLowerCase().trim();

    final filtered = modules.where((m) {
      if (!m.canAccess(
        isAdmin: isAdmin,
        isVIP: isVIP,
        isInstructor: isInstructor,
      )) return false;

      if (q.isEmpty) return true;

      final title = m.title.toLowerCase();
      final subtitle = m.subtitle.toLowerCase();
      final section = m.section.toLowerCase();

      return title.contains(q) ||
          subtitle.contains(q) ||
          section.contains(q);
    }).toList();

    filtered.sort((a, b) => (a.order).compareTo(b.order));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filterModules();

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "لا توجد نتائج",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "جرّب كلمة بحث مختلفة",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;

        if (width >= 1400) {
          crossAxisCount = 5;
        } else if (width >= 1100) {
          crossAxisCount = 4;
        } else if (width >= 800) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          itemCount: list.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final module = list[index];

            return CenterModuleCard(
              module: module,
              onTap: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => module.page),
                  );
                } catch (_) {}
              },
            );
          },
        );
      },
    );
  }
}