// 🔥 FINAL STABLE CATEGORIES ADMIN PAGE (NO FREEZE + SAFE + CLEAN)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class CategoriesAdminPage extends StatefulWidget {
  const CategoriesAdminPage({super.key});

  @override
  State<CategoriesAdminPage> createState() => _CategoriesAdminPageState();
}

class _CategoriesAdminPageState extends State<CategoriesAdminPage> {
  final controller = TextEditingController();
  String searchText = "";
  bool loading = false;

  // ================= ADD =================
  Future addCategory() async {
    String text = controller.text.trim();

    if (text.isEmpty) {
      show("اكتب اسم التصنيف ❗", Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      var exist = await FirebaseService.firestore
          .collection("categories")
          .where("title", isEqualTo: text)
          .get();

      if (exist.docs.isNotEmpty) {
        show("التصنيف موجود بالفعل ⚠️", Colors.orange);
        setState(() => loading = false);
        return;
      }

      await FirebaseService.firestore.collection("categories").add({
        "title": text,
        "order": DateTime.now().millisecondsSinceEpoch,
        "createdAt": FieldValue.serverTimestamp(),
      });

      controller.clear();
      show("تم إضافة التصنيف ✅", Colors.green);
    } catch (e) {
      show("خطأ: $e", Colors.red);
    }

    setState(() => loading = false);
  }

  // ================= UPDATE =================
  Future editCategory(String id, String oldTitle) async {
    final editController = TextEditingController(text: oldTitle);

    final ctx = context; // ✅ حفظ context

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "تعديل التصنيف",
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "إلغاء",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          // 🔥 SAVE BUTTON (FIXED)
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context); // ✅ ناخد navigator بدري

              String newTitle = editController.text.trim();
              if (newTitle.isEmpty) return;

              try {
                await FirebaseService.firestore
                    .collection("categories")
                    .doc(id)
                    .update({"title": newTitle});

                if (!mounted) return;

                navigator.pop(); // ✅ آمن بدون warning

                show("تم التعديل ✅", Colors.green);
              } catch (e) {
                debugPrint("Edit Error: $e");

                if (!mounted) return;

                show("❌ خطأ في التعديل", Colors.red);
              }
            },
            child: const Text(
              "حفظ",
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  Future deleteCategory(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("حذف التصنيف؟",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo')),
        content: const Text(
          "⚠️ حذف التصنيف لن يحذف الكورسات المرتبطة به ولكن سيؤثر على ترتيب العرض.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseService.firestore
                  .collection("categories")
                  .doc(id)
                  .delete();

              show("تم الحذف ❌", Colors.red);
            },
            child: const Text("حذف",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ================= ORDER =================
  Future updateOrder(List docs) async {
    for (int i = 0; i < docs.length; i++) {
      await docs[i].reference.update({"order": i});
    }
    show("تم تحديث الترتيب 🔄", Colors.green);
  }

  // ================= UI HELPER =================
  void show(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo')),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("📂 إدارة التصنيفات",
            style:
                TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              /// ➕ ADD SECTION
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("إضافة تصنيف جديد",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "مثال: قسم التمريض",
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 0),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        loading
                            ? const SizedBox(
                                width: 45,
                                height: 45,
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: CircularProgressIndicator(
                                      color: AppColors.gold, strokeWidth: 2),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(15)),
                                child: IconButton(
                                  icon: const Icon(Icons.add_rounded,
                                      color: Colors.black, size: 28),
                                  onPressed: addCategory,
                                ),
                              )
                      ],
                    ),
                  ],
                ),
              ),

              /// 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  onChanged: (val) => setState(() => searchText = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "ابحث في التصنيفات المضافة...",
                    hintStyle:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// 📋 LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore
                      .collection("categories")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("❌ خطأ في تحميل البيانات",
                            style: TextStyle(color: Colors.red)),
                      );
                    }

                    var docs = snapshot.data?.docs ?? [];

                    /// 🔥 SORT SAFE
                    docs.sort((a, b) {
                      var aData = a.data() as Map<String, dynamic>;
                      var bData = b.data() as Map<String, dynamic>;

                      int aOrder = aData['order'] ?? 0;
                      int bOrder = bData['order'] ?? 0;

                      return aOrder.compareTo(bOrder);
                    });

                    var filtered = docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      return (data['title'] ?? "")
                          .toLowerCase()
                          .contains(searchText.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off_outlined,
                                size: 60,
                                color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 10),
                            const Text("لا يوجد تصنيفات حالياً",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;

                        final item = filtered.removeAt(oldIndex);
                        filtered.insert(newIndex, item);

                        updateOrder(filtered);
                      },
                      itemBuilder: (context, index) {
                        var doc = filtered[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Container(
                          key: ValueKey(doc.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            title: Text(
                              data['title'] ?? "",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.reorder_rounded,
                                  color: AppColors.gold, size: 20),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      color: Colors.blue, size: 20),
                                  onPressed: () =>
                                      editCategory(doc.id, data['title']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.red, size: 20),
                                  onPressed: () => deleteCategory(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (loading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
              ),
            ),
        ],
      ),
    );
  }
}
