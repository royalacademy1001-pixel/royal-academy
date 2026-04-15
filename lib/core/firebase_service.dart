import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';

class FirebaseInit {
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static Future<void> init() async {
    if (_initialized) return;

    _initFuture ??= _initialize();
    await _initFuture;
  }

  static Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint("🔥 Firebase Initialized");
    } catch (e) {
      debugPrint("🔥 Firebase Init Error: $e");
      rethrow;
    } finally {
      _initFuture = null;
    }
  }
}

Future<T?> safeFirestoreCall<T>(Future<T> Function() call) async {
  try {
    await FirebaseInit.init();
    return await call();
  } catch (e) {
    debugPrint("🔥 Retry Firestore...");
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await FirebaseInit.init();
      return await call();
    } catch (e) {
      debugPrint("🔥 Final Firestore Error: $e");
      return null;
    }
  }
}

Future<T?> safeTimeout<T>(Future<T?> Function() call) async {
  try {
    await FirebaseInit.init();
    return await call().timeout(const Duration(seconds: 10));
  } catch (_) {
    debugPrint("⏱ Timeout");
    return null;
  }
}

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final Map<String, DateTime> _lock = {};
  static final Map<String, String> _imageCache = {};
  static final Map<String, Future<String>> _imageFutureCache = {};
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheTime = {};

  static bool canRun(String key, {int seconds = 10}) {
    final now = DateTime.now();

    if (_lock.containsKey(key)) {
      final last = _lock[key];
      if (last != null && now.difference(last).inSeconds < seconds) {
        return false;
      }
    }

    _lock[key] = now;
    return true;
  }

  static void clearImageCache({String? url}) {
    final clean = url?.trim();

    if (clean == null || clean.isEmpty) {
      _imageCache.clear();
      _imageFutureCache.clear();
      return;
    }

    _imageCache.removeWhere((key, _) => key.startsWith("$clean|"));
    _imageFutureCache.removeWhere((key, _) => key.startsWith("$clean|"));
  }

  static void clearMemoryCache({String? key}) {
    if (key == null) {
      _memoryCache.clear();
      _memoryCacheTime.clear();
      return;
    }
    _memoryCache.remove(key);
    _memoryCacheTime.remove(key);
  }

  static Future<User?> refreshCurrentUser() async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return null;

      await user.reload();

      final refreshed = auth.currentUser;
      if (refreshed == null) return null;

      await refreshed.getIdToken(true);
      return refreshed;
    } catch (e) {
      debugPrint("🔥 Auth Refresh Error: $e");
      return auth.currentUser;
    }
  }

  static Future<void> safeUpdate(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseInit.init();
      await safeFirestoreCall(() => ref.set(data, SetOptions(merge: true)));
    } catch (e) {
      debugPrint("🔥 Safe Update Error: $e");
    }
  }

  static Future<void> safeDelete(DocumentReference ref) async {
    try {
      await FirebaseInit.init();
      await safeFirestoreCall(() => ref.delete());
    } catch (e) {
      debugPrint("🔥 Safe Delete Error: $e");
    }
  }

  static Future<DocumentReference?> safeAdd(
    CollectionReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseInit.init();
      return await safeFirestoreCall(() => ref.add(data));
    } catch (e) {
      debugPrint("🔥 Safe Add Error: $e");
      return null;
    }
  }

  static Future<DocumentSnapshot?> cachedDoc(
    String path, {
    int seconds = 10,
  }) async {
    final now = DateTime.now();

    if (_memoryCache.containsKey(path) &&
        _memoryCacheTime.containsKey(path)) {
      final last = _memoryCacheTime[path];
      if (last != null && now.difference(last).inSeconds < seconds) {
        return _memoryCache[path];
      }
    }

    try {
      final doc = await safeFirestoreCall(
        () => firestore.doc(path).get(),
      );

      if (doc != null) {
        _memoryCache[path] = doc;
        _memoryCacheTime[path] = now;
      }

      return doc;
    } catch (_) {
      return null;
    }
  }

  static String fixImage(String url, {String? version}) {
    final clean = url.trim();
    if (clean.isEmpty) return clean;

    try {
      if (clean.startsWith("gs://")) return clean;

      if (clean.startsWith("http")) {
        final uri = Uri.tryParse(clean);
        if (uri == null) return clean;

        final qp = Map<String, String>.from(uri.queryParameters);

        if (version != null && version.trim().isNotEmpty) {
          qp['v'] = version.trim();
          qp['t'] = DateTime.now().millisecondsSinceEpoch.toString();
        }

        return uri.replace(queryParameters: qp).toString();
      }

      return clean;
    } catch (e) {
      debugPrint("🔥 Image Fix Error: $e");
      return clean;
    }
  }

  static Future<String> resolveImageUrl(
    String url, {
    String? version,
    bool forceRefresh = false,
  }) async {
    final clean = url.trim();
    if (clean.isEmpty) return clean;

    final cacheKey = "$clean|${version ?? ""}";

    if (forceRefresh) {
      _imageCache.remove(cacheKey);
      _imageFutureCache.remove(cacheKey);
    }

    final cached = _imageCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final pending = _imageFutureCache[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _resolveInternal(clean, version: version);
    _imageFutureCache[cacheKey] = future;

    try {
      final result = await future;
      _imageCache[cacheKey] = result;
      return result;
    } catch (e) {
      debugPrint("🔥 Resolve Image Future Error: $e");
      return clean;
    } finally {
      _imageFutureCache.remove(cacheKey);
    }
  }

  static Future<String> _resolveInternal(
    String clean, {
    String? version,
  }) async {
    try {
      if (clean.startsWith("gs://")) {
        final downloadUrl = await storage.refFromURL(clean).getDownloadURL();
        return fixImage(downloadUrl, version: version);
      }

      if (clean.startsWith("http") && !clean.contains("alt=media")) {
        try {
          final ref = storage.refFromURL(clean);
          final downloadUrl = await ref.getDownloadURL();
          return fixImage(downloadUrl, version: version);
        } catch (_) {}
      }

      final fixed = fixImage(clean, version: version);
      if (fixed.isEmpty) return clean;
      if (!fixed.startsWith("http")) return clean;

      return fixed;
    } catch (e) {
      debugPrint("🔥 Resolve Image Error: $e");
      return clean;
    }
  }

  static Future<void> logout() async {
    try {
      await FirebaseInit.init();

      if (!kIsWeb) {
        try {
          await messaging.deleteToken();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }

    clearImageCache();
    clearMemoryCache();
    await auth.signOut();
  }

  static Future<Map<String, dynamic>> getUserData(
      {bool refresh = false}) async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return {};

      if (refresh) {
        try {
          await user.reload();
        } catch (_) {}
      }

      final cacheKey = "user_${user.uid}";

      if (!refresh &&
          _memoryCache.containsKey(cacheKey) &&
          _memoryCacheTime.containsKey(cacheKey)) {
        final last = _memoryCacheTime[cacheKey];
        if (last != null &&
            DateTime.now().difference(last).inSeconds < 15) {
          return Map<String, dynamic>.from(_memoryCache[cacheKey] ?? {});
        }
      }

      final doc = await safeFirestoreCall(
        () => firestore.collection("users").doc(user.uid).get(),
      );

      if (doc == null || !doc.exists) return {};

      final data = doc.data();
      if (data == null) return {};

      _memoryCache[cacheKey] = data;
      _memoryCacheTime[cacheKey] = DateTime.now();

      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint("🔥 getUserData Error: $e");
      return {};
    }
  }

  static final Map<String, DateTime> _xpLock = {};

  static bool canAddXP(String lessonId) {
    final now = DateTime.now();

    if (_xpLock.containsKey(lessonId)) {
      final last = _xpLock[lessonId];
      if (last != null && now.difference(last).inSeconds < 10) {
        return false;
      }
    }

    _xpLock[lessonId] = now;
    return true;
  }

  static Future<void> addXP(int xp) async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return;

      final ref = firestore.collection("users").doc(user.uid);

      await safeFirestoreCall(() async {
        await ref.update({
          "xp": FieldValue.increment(xp),
        });
      });
    } catch (e) {
      debugPrint("🔥 addXP Error: $e");
    }
  }

  static String _contentTypeFromName(String? name) {
    final lower = (name ?? "").toLowerCase();

    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".gif")) return "image/gif";
    if (lower.endsWith(".webp")) return "image/webp";
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";

    return "application/octet-stream";
  }

  static Future<String?> uploadCourseImage(Uint8List bytes, String fileName) async {
    try {
      await FirebaseInit.init();

      final user = auth.currentUser;
      if (user == null) return null;

      final userDoc = await firestore.collection("users").doc(user.uid).get();
      final data = userDoc.data() ?? {};

      if (data['blocked'] == true) return null;
      if (data['isAdmin'] != true && data['instructorApproved'] != true) return null;

      final ref = storage.ref().child("courses/images/$fileName");

      final metadata = SettableMetadata(contentType: _contentTypeFromName(fileName));

      final task = ref.putData(bytes, metadata);

      final snapshot = await task;

      if (snapshot.state != TaskState.success) return null;

      final url = await ref.getDownloadURL();

      if (url.isEmpty || !url.startsWith("http")) return null;

      clearImageCache(url: url);

      return url;
    } catch (e) {
      debugPrint("🔥 uploadCourseImage Error: $e");
      return null;
    }
  }
}