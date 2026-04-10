class VipStudentModel {
  final String id;
  final String name;
  final String phone;
  final String? email;

  final String? linkedUserId; // 🔗 الربط مع حساب البرنامج

  final bool isActive;
  final DateTime createdAt;

  VipStudentModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.linkedUserId,
    required this.isActive,
    required this.createdAt,
  });

  /// 🔥 هل الطالب مربوط بحساب
  bool get isLinked => linkedUserId != null && linkedUserId!.isNotEmpty;

  /// 🔥 من Firestore
  factory VipStudentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return VipStudentModel(
      id: id,
      name: data['name'] ?? "",
      phone: data['phone'] ?? "",
      email: data['email'],
      linkedUserId: data['linkedUserId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as dynamic?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 🔥 للتحويل لـ Firestore
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "phone": phone,
      "email": email,
      "linkedUserId": linkedUserId,
      "isActive": isActive,
      "createdAt": createdAt,
      "type": "vip_manual", // مهم جدًا
    };
  }
}