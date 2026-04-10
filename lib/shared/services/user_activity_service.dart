import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class UserActivityService {
  static Future<void> addXP(int xp) async {
    try {
      await FirebaseInit.init();

      final user = FirebaseService.auth.currentUser;
      if (user == null || xp <= 0) return;

      final ref = FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid);

      await ref.update({
        "xp": FieldValue.increment(xp),
        "lastXPUpdate": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}