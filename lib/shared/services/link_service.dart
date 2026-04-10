import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';

class LinkService {
  /// 🔗 ربط VIP مع user
  static Future<void> linkVipToUser({
    required String vipId,
    required String userId,
  }) async {
    await FirebaseInit.init();

    final vipRef =
        FirebaseService.firestore.collection("vip_students").doc(vipId);

    final userRef =
        FirebaseService.firestore.collection("users").doc(userId);

    await FirebaseService.firestore.runTransaction((tx) async {
      tx.update(vipRef, {
        "linkedUserId": userId,
      });

      tx.set(userRef, {
        "vipId": vipId,
        "isVIP": true,
      }, SetOptions(merge: true));
    });
  }

  /// ❌ فك الربط
  static Future<void> unlinkVip(String vipId, String userId) async {
    await FirebaseInit.init();

    final vipRef =
        FirebaseService.firestore.collection("vip_students").doc(vipId);

    final userRef =
        FirebaseService.firestore.collection("users").doc(userId);

    await FirebaseService.firestore.runTransaction((tx) async {
      tx.update(vipRef, {
        "linkedUserId": null,
      });

      tx.set(userRef, {
        "vipId": null,
        "isVIP": false,
      }, SetOptions(merge: true));
    });
  }
}