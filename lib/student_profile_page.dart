// 🔥 IMPORTS FIRST
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_widget.dart';

import '../user_payments_page.dart';
import '../course_details_page.dart';
import '../payment/payment_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final name = TextEditingController();
  final phone = TextEditingController();

  String email = "";
  String imageUrl = "";

  bool validSubscription = false;
  bool isAdmin = false;

  bool instructorRequest = false;
  bool instructorApproved = false;

  String? subscriptionEnd;
  List enrolledCourses = [];

  File? profileImage;
  final picker = ImagePicker();

  bool loading = false;

  Map<String, String> courseNames = {};

  static final Map<String, String> _courseCache = {};

  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    loadData();
    _listenUser();
  }

  void _listenUser() {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    _userStream = FirebaseService.firestore
        .collection(AppConstants.users)
        .doc(user.uid)
        .snapshots();

    _userStream!.listen((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      name.text = data['name'] ?? "";
      phone.text = data['phone'] ?? "";
      imageUrl = data['image'] ?? "";

      enrolledCourses = data['enrolledCourses'] ?? [];
      isAdmin = data['isAdmin'] ?? false;
      subscriptionEnd = data['subscriptionEnd'];

      instructorRequest = data['instructorRequest'] ?? false;
      instructorApproved = data['instructorApproved'] ?? false;

      if (subscriptionEnd != null) {
        DateTime? end = DateTime.tryParse(subscriptionEnd!);
        if (end != null) {
          validSubscription = end.isAfter(DateTime.now());
        }
      }

      if (isAdmin || instructorApproved) validSubscription = true;

      loadCoursesNames();

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future loadData() async {
    try {
      final data = await FirebaseService.getUserData();

      name.text = data['name'] ?? "";
      phone.text = data['phone'] ?? "";
      email = FirebaseService.auth.currentUser?.email ?? "";
      imageUrl = data['image'] ?? "";

      enrolledCourses = data['enrolledCourses'] ?? [];
      isAdmin = data['isAdmin'] ?? false;
      subscriptionEnd = data['subscriptionEnd'];

      instructorRequest = data['instructorRequest'] ?? false;
      instructorApproved = data['instructorApproved'] ?? false;

      if (subscriptionEnd != null) {
        DateTime? end = DateTime.tryParse(subscriptionEnd!);
        if (end != null) {
          validSubscription = end.isAfter(DateTime.now());
        }
      }

      if (isAdmin || instructorApproved) validSubscription = true;

      await loadCoursesNames();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Profile Load Error: $e");
    }
  }

  Future loadCoursesNames() async {
    final futures = enrolledCourses.map((id) async {
      if (_courseCache.containsKey(id)) {
        courseNames[id] = _courseCache[id]!;
        return;
      }

      try {
        var doc = await FirebaseService.firestore
            .collection(AppConstants.courses)
            .doc(id)
            .get();

        if (doc.exists) {
          String title = doc.data()?['title'] ?? "Course";
          courseNames[id] = title;
          _courseCache[id] = title;
        }
      } catch (_) {}
    });

    await Future.wait(futures);

    if (mounted) setState(() {});
  }

  Future pickImage() async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && !kIsWeb) {
      setState(() => profileImage = File(picked.path));
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      String name =
          DateTime.now().millisecondsSinceEpoch.toString();

      var ref = FirebaseService.storage
          .ref()
          .child("${AppConstants.profileFolder}/$name.jpg");

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return imageUrl;
    }
  }

  Future saveData() async {
    var user = FirebaseService.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      String? url = imageUrl;

      if (profileImage != null && !kIsWeb) {
        url = await uploadImage(profileImage!);
      }

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "name": name.text.trim(),
        "phone": phone.text.trim(),
        "image": url,
      }, SetOptions(merge: true));

      showSnack("تم الحفظ ✅");
    } catch (e) {
      debugPrint("Save Error: $e");
      showSnack("❌ خطأ", color: Colors.red);
    }

    if (mounted) setState(() => loading = false);
  }

  Future requestInstructor() async {
    var user = FirebaseService.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      await FirebaseService.firestore
          .collection("instructor_requests")
          .doc(user.uid)
          .set({
        "userId": user.uid,
        "email": user.email,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "instructorRequest": true,
        "instructorApproved": false,
      }, SetOptions(merge: true));

      showSnack("تم إرسال الطلب 📩");
    } catch (_) {
      showSnack("❌ فشل الطلب", color: Colors.red);
    }

    if (mounted) setState(() => loading = false);
  }

  String getStatusText() {
    if (isAdmin) return "👑 Admin";
    if (instructorApproved) return "🎓 Instructor";
    if (validSubscription) return "⭐ VIP";
    return "🔒 غير مشترك";
  }

  Color getStatusColor() {
    if (isAdmin) return Colors.amber;
    if (instructorApproved) return Colors.blue;
    if (validSubscription) return Colors.green;
    return Colors.red;
  }

  void showSnack(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ImageProvider? imageProvider;

    if (!kIsWeb && profileImage != null) {
      imageProvider = FileImage(profileImage!);
    } else if (imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("👤 الملف الشخصي",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [

                profileCard(imageProvider),

                const SizedBox(height: 20),

                if (!isAdmin && !instructorApproved && !instructorRequest)
                  CustomButton(
                    text: "📩 اطلب أن تصبح مدرس",
                    onPressed: requestInstructor,
                  ),

                if (!isAdmin && instructorRequest && !instructorApproved)
                  const Text(
                    "⏳ طلبك قيد المراجعة",
                    style: TextStyle(color: Colors.orange),
                  ),

                if (!isAdmin && instructorApproved)
                  CustomButton(
                    text: "🎓 لوحة المدرس",
                    onPressed: () {
                      Navigator.pushNamed(context, "/instructor_dashboard");
                    },
                  ),

                const SizedBox(height: 20),

                coursesSection(),

                const SizedBox(height: 20),

                CustomButton(
                  text: "💰 مدفوعاتي",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserPaymentsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                CustomTextField(hint: "الاسم", controller: name),
                const SizedBox(height: 10),
                CustomTextField(hint: "رقم الهاتف", controller: phone),

                const SizedBox(height: 15),

                CustomButton(text: "💾 حفظ", onPressed: saveData),

                const SizedBox(height: 20),

                CustomButton(
                  text: "🚪 تسجيل الخروج",
                  onPressed: () async {
                    setState(() => loading = true);

                    await FirebaseService.auth.signOut();

                    if (!mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          if (loading)
            Container(
              color: Colors.black54,
              child: const Center(child: LoadingWidget()),
            ),
        ],
      ),
    );
  }

  Widget profileCard(ImageProvider? imageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.premiumCard,
      child: Column(
        children: [

          GestureDetector(
            onTap: pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.gold,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.camera_alt, color: Colors.black)
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            name.text.isEmpty ? "اسم المستخدم" : name.text,
            style: const TextStyle(color: Colors.white),
          ),

          Text(email, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: getStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(getStatusText(),
                style: const TextStyle(color: Colors.white)),
          ),

          if (!validSubscription && !isAdmin && !instructorApproved)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                style: AppColors.goldButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentPage()),
                  );
                },
                child: const Text("🔥 اشترك الآن"),
              ),
            ),
        ],
      ),
    );
  }

  Widget coursesSection() {

    if (enrolledCourses.isEmpty || isAdmin) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text("📚 كورساتي",
            style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enrolledCourses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {

            String id = enrolledCourses[index];
            String title = courseNames[id] ?? id;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsPage(
                      title: title,
                      courseId: id,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: AppColors.premiumCard,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book,
                        color: AppColors.gold, size: 30),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}