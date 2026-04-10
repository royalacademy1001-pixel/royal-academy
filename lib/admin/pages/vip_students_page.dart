import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../shared/models/vip_student_model.dart';
import '../../shared/services/vip_student_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';

class VipStudentsPage extends StatefulWidget {
  const VipStudentsPage({super.key});

  @override
  State<VipStudentsPage> createState() => _VipStudentsPageState();
}

class _VipStudentsPageState extends State<VipStudentsPage> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("طلاب السنتر VIP"),
        backgroundColor: AppColors.black,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () {
          Navigator.pushNamed(context, "/add-vip");
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),

      body: Column(
        children: [

          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) {
                setState(() => search = val.toLowerCase().trim());
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.gold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          /// 📋 List
          Expanded(
            child: StreamBuilder<List<VipStudentModel>>(
              stream: VipStudentService.streamStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingWidget();
                }

                final students = snapshot.data!;

                /// 🔍 Filter
                final filtered = students.where((s) {
                  final name = s.name.toLowerCase();
                  final phone = s.phone.toLowerCase();

                  return search.isEmpty ||
                      name.contains(search) ||
                      phone.contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyWidget(text: "لا توجد نتائج");
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];

                    return AppCard(
                      child: Row(
                        children: [

                          /// 👤 Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                color: AppColors.gold),
                          ),

                          const SizedBox(width: 12),

                          /// 📄 Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  s.phone,
                                  style: const TextStyle(
                                      color: Colors.grey),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Icon(
                                      s.isLinked
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: s.isLinked
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      s.isLinked
                                          ? "مرتبط"
                                          : "غير مرتبط",
                                      style: TextStyle(
                                        color: s.isLinked
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// 🔗 Link
                          IconButton(
                            icon: const Icon(Icons.link,
                                color: Colors.blue),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                "/link-vip",
                                arguments: s,
                              );
                            },
                          ),

                          /// 🗑 Delete
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () async {
                              await VipStudentService
                                  .deleteStudent(s.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}