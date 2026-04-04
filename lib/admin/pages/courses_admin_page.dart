// 🔥 FINAL ULTRA COURSES ADMIN PAGE (PRO MAX++ MARKETPLACE FINAL)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class CoursesAdminPage extends StatefulWidget {
  const CoursesAdminPage({super.key});

  @override
  State<CoursesAdminPage> createState() => _CoursesAdminPageState();
}

class _CoursesAdminPageState extends State<CoursesAdminPage>
    with SingleTickerProviderStateMixin {

  late TabController tabController;

  String? selectedCourseId;
  String selectedCourseName = "";
  int lessonsCount = 0;

  String searchText = "";

  final lessonTitle = TextEditingController();
  final video = TextEditingController();

  String selectedType = "video";

  File? pickedFile;
  final picker = ImagePicker();

  bool loading = false;

  final rejectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  Future<String?> getRejectReason() async {
    rejectController.clear();

    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("سبب الرفض",
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: TextField(
          controller: rejectController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "اكتب سبب الرفض هنا...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, rejectController.text.trim()),
              child: const Text("تأكيد", style: TextStyle(color: AppColors.gold))),
        ],
      ),
    );
  }

  Future sendNotification(String userId, String title, String body) async {
    try {
      await FirebaseService.firestore
          .collection(AppConstants.notifications)
          .add({
        "title": title,
        "body": body,
        "userId": userId,
        "type": "user",
        "seen": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ================= APPROVAL =================
  Future approveCourse(String id) async {
    bool confirm = await _confirm("هل أنت متأكد من الموافقة على الكورس؟");
    if (!confirm) return;

    var doc = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .get();

    var data = doc.data() ?? {};
    String instructorId = (data['instructorId'] ?? "").toString();

    await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .update({
      "approved": true,
      "status": "approved",
      "rejectReason": ""
    });

    if (instructorId.isNotEmpty) {
      await sendNotification(
        instructorId,
        "تم قبول الكورس 🎉",
        "تمت الموافقة على الكورس الخاص بك: ${data['title']}",
      );
    }

    show("تم الموافقة ✅");
  }

  Future rejectCourse(String id) async {
    bool confirm = await _confirm("هل تريد رفض هذا الكورس؟");
    if (!confirm) return;

    String? reason = await getRejectReason();
    if (reason == null || reason.isEmpty) return;

    var doc = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .get();

    var data = doc.data() ?? {};
    String instructorId = (data['instructorId'] ?? "").toString();

    await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .update({
      "approved": false,
      "status": "rejected",
      "rejectReason": reason
    });

    if (instructorId.isNotEmpty) {
      await sendNotification(
        instructorId,
        "تم رفض الكورس ❌",
        "سبب الرفض: $reason",
      );
    }

    show("تم الرفض ❌");
  }

  Future<bool> _confirm(String text) async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.black,
            title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("تأكيد", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  // ================= PICK FILE =================
  Future pickFile() async {
    if (selectedType == "video") {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) pickedFile = File(picked.path);
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) pickedFile = File(picked.path);
    }

    if (pickedFile != null) {
      show("تم اختيار الملف ✅");
      setState(() {});
    }
  }

  // ================= UPLOAD =================
  Future<String?> uploadFile(File file) async {
    try {
      String name = DateTime.now().millisecondsSinceEpoch.toString();

      String folder = selectedType == "video"
          ? AppConstants.videosFolder
          : selectedType == "pdf"
              ? "pdfs"
              : "audios";

      var ref = FirebaseService.storage.ref().child("$folder/$name");

      await ref.putFile(file);

      return await ref.getDownloadURL();

    } catch (_) {
      return null;
    }
  }

  // ================= SELECT COURSE =================
  Future selectCourse(String id, String name) async {

    var lessons = await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .collection(AppConstants.lessons)
        .get();

    setState(() {
      selectedCourseId = id;
      selectedCourseName = name;
      lessonsCount = lessons.docs.length;
    });

    show("📌 تم اختيار: $name");
  }

  // ================= ADD LESSON =================
  Future addLesson() async {

    if (selectedCourseId == null) {
      show("اختار كورس الأول ❗");
      return;
    }

    if (lessonTitle.text.isEmpty) {
      show("اكتب عنوان الدرس ❗");
      return;
    }

    setState(() => loading = true);

    try {

      String? fileUrl;

      if (pickedFile != null) {
        fileUrl = await uploadFile(pickedFile!);
      } else if (video.text.isNotEmpty) {
        fileUrl = video.text.trim();
      }

      if (fileUrl == null || fileUrl.isEmpty) {
        show("أضف ملف أو لينك ❗");
        setState(() => loading = false);
        return;
      }

      int order = lessonsCount + 1;

      await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(selectedCourseId)
          .collection(AppConstants.lessons)
          .add({
        "title": lessonTitle.text.trim(),
        "type": selectedType,
        "contentUrl": fileUrl,
        "video": selectedType == "video" ? fileUrl : "",
        "order": order,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(selectedCourseId)
          .update({
        "lessonsCount": FieldValue.increment(1),
      });

      clearLesson();

      setState(() {
        lessonsCount++;
      });

      show("تم إضافة المحتوى ✅");

    } catch (_) {
      show("خطأ ❌");
    }

    setState(() => loading = false);
  }

  void clearLesson() {
    lessonTitle.clear();
    video.clear();
    pickedFile = null;
    selectedType = "video";
  }

  // ================= DELETE =================
  Future deleteCourse(String id) async {

    bool confirm = await _confirm("حذف الكورس نهائياً؟");
    if (!confirm) return;

    await FirebaseService.firestore
        .collection(AppConstants.courses)
        .doc(id)
        .delete();

    show("تم حذف الكورس ❌");
  }

  // ================= EDIT =================
  Future editCourse(DocumentSnapshot doc) async {

    var data = doc.data() as Map<String, dynamic>;

    TextEditingController title =
        TextEditingController(text: data['title']);
    TextEditingController price =
        TextEditingController(text: "${data['price']}");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("تعديل بيانات الكورس", style: TextStyle(color: AppColors.gold, fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "اسم الكورس", labelStyle: TextStyle(color: Colors.grey)),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "السعر", labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            onPressed: () async {
              await doc.reference.update({
                "title": title.text,
                "price": int.tryParse(price.text) ?? 0,
              });
              Navigator.pop(context);
              show("تم التعديل ✅");
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📚 إدارة الكورسات",
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "كل الكورسات"),
            Tab(text: "⏳ Pending"),
            Tab(text: "إضافة محتوى"),
          ],
        ),
      ),

      body: Stack(
        children: [
          TabBarView(
            controller: tabController,
            children: [
              _coursesList(),
              _coursesList(pending: true),
              _addContent(),
            ],
          ),
          if (loading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coursesList({bool pending = false}) {
    return Column(
      children: [
        if (!pending)
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث عن كورس بالاسم...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => searchText = val),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection(AppConstants.courses)
                .snapshots(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }

              var courses = snapshot.data!.docs.where((c) {
                var d = c.data() as Map<String, dynamic>;
                String status = (d['status'] ?? "approved").toString();

                if (pending) return status == "pending";

                return (d['title'] ?? "")
                    .toString()
                    .toLowerCase()
                    .contains(searchText.toLowerCase());
              }).toList();

              if (courses.isEmpty) {
                return Center(child: Text(pending ? "لا توجد طلبات معلقة" : "لا توجد كورسات متاحة", style: const TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: courses.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {

                  var c = courses[index];
                  var d = c.data() as Map<String, dynamic>;
                  String status = (d['status'] ?? "approved").toString();
                  String image = (d['image'] ?? "").toString();

                  Color color = status == "approved"
                      ? Colors.green
                      : status == "rejected"
                          ? Colors.red
                          : Colors.orange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selectedCourseId == c.id ? AppColors.gold : Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.gold.withOpacity(0.1),
                        ),
                        child: image.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(image, fit: BoxFit.cover))
                            : const Icon(Icons.menu_book, color: AppColors.gold),
                      ),
                      title: Text(d['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: color, size: 10),
                            const SizedBox(width: 6),
                            Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text("${d['price']} EGP", style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                          ],
                        ),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == "pending")
                            _actionCircle(Icons.check, Colors.green, () => approveCourse(c.id)),
                          if (status == "pending")
                            const SizedBox(width: 8),
                          if (status == "pending")
                            _actionCircle(Icons.close, Colors.red, () => rejectCourse(c.id)),
                          if (status != "pending")
                            _actionCircle(Icons.edit_note, Colors.blue, () => editCourse(c)),
                          const SizedBox(width: 8),
                          _actionCircle(Icons.delete_sweep_outlined, Colors.red, () => deleteCourse(c.id)),
                        ],
                      ),

                      onTap: () => selectCourse(c.id, d['title']),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCircle(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _addContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.gold.withOpacity(0.2))),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedCourseId == null ? "برجاء اختيار كورس من القائمة أولاً" : "إضافة محتوى لـ: $selectedCourseName",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text("نوع المحتوى", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                dropdownColor: AppColors.black,
                items: const [
                  DropdownMenuItem(value: "video", child: Text("🎥 فيديو تعليمي", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: "pdf", child: Text("📄 ملف PDF / ملخص", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: "audio", child: Text("🎧 ملف صوتي", style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _inputField(lessonTitle, "عنوان الدرس / المحتوى", Icons.title),
          const SizedBox(height: 20),
          _inputField(video, "رابط خارجي (اختياري)", Icons.link),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: pickFile,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text("رفع ملف", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: addLesson,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text("حفظ الدرس", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (pickedFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text("📂 تم اختيار: ${pickedFile!.path.split('/').last}", style: const TextStyle(color: Colors.green, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.gold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}