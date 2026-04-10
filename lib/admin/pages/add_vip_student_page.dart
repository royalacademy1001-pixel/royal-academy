import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../shared/models/vip_student_model.dart';
import '../../shared/services/vip_student_service.dart';

class AddVipStudentPage extends StatefulWidget {
  const AddVipStudentPage({super.key});

  @override
  State<AddVipStudentPage> createState() => _AddVipStudentPageState();
}

class _AddVipStudentPageState extends State<AddVipStudentPage> {
  final name = TextEditingController();
  final phone = TextEditingController();

  bool loading = false;

  Future<void> save() async {
    if (name.text.isEmpty || phone.text.isEmpty) return;

    setState(() => loading = true);

    final student = VipStudentModel(
      id: "",
      name: name.text,
      phone: phone.text,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await VipStudentService.addStudent(student);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إضافة طالب"),
        backgroundColor: AppColors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "الاسم"),
            ),
            TextField(
              controller: phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "الموبايل"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : save,
              child: const Text("حفظ"),
            )
          ],
        ),
      ),
    );
  }
}