import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/user_activity_service.dart';

class VideoController {
  final String videoUrl;
  final String courseId;
  final String lessonId;
  final bool isFree;

  VideoController({
    required this.videoUrl,
    required this.courseId,
    required this.lessonId,
    required this.isFree,
  });

  bool loading = true;
  bool hasAccess = false;
  bool isBlocked = false;
  bool videoError = false;

  bool isYoutube = false;
  bool isPdf = false;
  bool isAudio = false;

  VideoPlayerController? videoController;
  ChewieController? chewieController;
  YoutubePlayerController? youtubeController;
  AudioPlayer? audioPlayer;

  int currentSecond = 0;
  int maxWatchedSecond = 0;
  int totalSeconds = 0;
  double progress = 0;

  bool completedSent = false;
  bool savingNow = false;
  bool askedResume = false;
  bool initializedOnce = false;

  Timer? youtubeTimer;

  Future<void> checkAccess() async {
    try {
      var user = FirebaseService.auth.currentUser;

      if (user == null) {
        hasAccess = isFree;
        return;
      }

      final data = await AuthService.getUserData();

      bool isAdmin = data['isAdmin'] == true;
      bool subscribed = data['subscribed'] == true;
      isBlocked = data['blocked'] == true;

      String? endDate = data['subscriptionEnd']?.toString();

      bool valid =
          DateTime.tryParse(endDate ?? "")?.isAfter(DateTime.now()) ?? false;

      List unlocked = data['unlockedCourses'] ?? [];

      var courseDoc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(courseId)
          .get();

      bool courseFree = courseDoc.data()?['isFree'] == true;

      hasAccess = !isBlocked &&
          (isAdmin ||
              isFree ||
              courseFree ||
              (subscribed && valid) ||
              unlocked.contains(courseId));
    } catch (_) {
      hasAccess = isFree;
    }
  }

  String extractYoutubeId(String url) {
    try {
      final converted = YoutubePlayerController.convertUrlToId(url);
      if (converted != null && converted.isNotEmpty) {
        return converted;
      }
    } catch (_) {}

    final uri = Uri.tryParse(url);
    if (uri == null) return "";

    if (uri.queryParameters.containsKey("v")) {
      return uri.queryParameters["v"] ?? "";
    }

    return "";
  }

  Future<void> initVideo(BuildContext context) async {
    String url = videoUrl.trim();

    if (url == "null") url = "";

    if (url.isEmpty) {
      videoError = true;
      return;
    }

    if (!url.startsWith("http")) {
      videoError = true;
      return;
    }

    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains(".pdf")) {
      isPdf = true;
      return;
    }

    if (lowerUrl.endsWith(".mp3") || lowerUrl.endsWith(".wav")) {
      isAudio = true;
      audioPlayer = AudioPlayer();

      try {
        await audioPlayer!.setUrl(url);

        audioPlayer!.positionStream.listen((pos) {
          currentSecond = pos.inSeconds;
        });

        audioPlayer!.durationStream.listen((dur) {
          if (dur != null) {
            totalSeconds = dur.inSeconds;
          }
        });
      } catch (_) {
        videoError = true;
      }

      return;
    }

    if (lowerUrl.contains("youtube") || lowerUrl.contains("youtu.be")) {
      isYoutube = true;

      String id = extractYoutubeId(url);

      if (id.isEmpty) {
        videoError = true;
        return;
      }

      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
      );

      youtubeTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (youtubeController == null) {
          timer.cancel();
          return;
        }

        try {
          final position = await youtubeController!.currentTime;
          final duration = await youtubeController!.duration;

          currentSecond = position.toInt();
          totalSeconds = duration.toInt();

          if (totalSeconds > 0) {
            progress = currentSecond / totalSeconds;
          }

          if (currentSecond > maxWatchedSecond) {
            maxWatchedSecond = currentSecond;
          }

          if (currentSecond % 5 == 0 && !savingNow) {
            savingNow = true;
            saveProgress().then((_) {
              savingNow = false;
            });
          }

          if (progress >= 0.9 && !completedSent) {
            completedSent = true;
            saveProgress();
            markCompleted();
          }

        } catch (_) {}
      });

      return;
    }

    url = "$url?v=${DateTime.now().millisecondsSinceEpoch}";

    try {
      videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await videoController!.initialize();

      totalSeconds = videoController!.value.duration.inSeconds;

      await handleResume(context);

      chewieController = ChewieController(
        videoPlayerController: videoController!,
        autoPlay: true,
        allowFullScreen: true,
      );

      startListener();
    } catch (e) {
      videoError = true;
      debugPrint("Video init error: $e");
    }
  }

  void startListener() {
    videoController?.addListener(() {
      if (videoController == null) return;

      final value = videoController!.value;

      if (!value.isInitialized) return;

      currentSecond = value.position.inSeconds;

      final duration = value.duration;

      if (duration.inSeconds <= 0) return;

      totalSeconds = duration.inSeconds;

      if (currentSecond > maxWatchedSecond + 10) {
        videoController!.seekTo(Duration(seconds: maxWatchedSecond));
        return;
      }

      if (currentSecond > maxWatchedSecond) {
        maxWatchedSecond = currentSecond;
      }

      progress = maxWatchedSecond / totalSeconds;

      if (currentSecond % 5 == 0 && !savingNow) {
        savingNow = true;
        saveProgress().then((_) {
          savingNow = false;
        });
      }

      if (progress >= 0.9 && !completedSent) {
        completedSent = true;
        saveProgress();
        markCompleted();
      }
    });
  }

  Future<void> handleResume(BuildContext context) async {
    if (askedResume) return;
    askedResume = true;

    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null || videoController == null) return;

      var doc = await FirebaseService.firestore
          .collection(AppConstants.progress)
          .doc("${user.uid}_${lessonId}")
          .get();

      if (!doc.exists) return;

      int sec = doc.data()?['watchedSeconds'] ?? 0;
      if (sec < 5) return;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("استكمال المشاهدة؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("من البداية"),
            ),
            TextButton(
              onPressed: () {
                videoController!.seekTo(Duration(seconds: sec));
                maxWatchedSecond = sec;
                Navigator.pop(context);
              },
              child: const Text("استكمال"),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> saveProgress() async {
    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection(AppConstants.progress)
          .doc("${user.uid}_${lessonId}")
          .set({
        "userId": user.uid,
        "courseId": courseId,
        "lessonId": lessonId,
        "watchedSeconds": maxWatchedSecond,
        "totalSeconds": totalSeconds,
        "progress": progress,
        "completed": progress >= 0.9,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> markCompleted() async {
    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await UserActivityService.addXP(AppConstants.xpPerLesson);

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "lastCompletedLesson": lessonId,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void dispose() {
    try {
      youtubeTimer?.cancel();
      videoController?.dispose();
      chewieController?.dispose();
      youtubeController?.close();
      audioPlayer?.dispose();
    } catch (_) {}
  }
}