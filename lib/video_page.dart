import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:just_audio/just_audio.dart';

import 'core/firebase_service.dart';
import 'core/constants.dart';
import 'core/colors.dart';

class VideoGuard {
  static bool saving = false;
  static int lastSave = 0;

  static bool canSave(int sec) {
    if (saving) return false;
    if ((sec - lastSave).abs() < 10) return false;

    lastSave = sec;
    return true;
  }
}

Widget videoSafe(Widget child) {
  return RepaintBoundary(child: child);
}

class VideoPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String courseId;
  final String lessonId;
  final bool isFree;

  const VideoPage({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.courseId,
    required this.lessonId,
    this.isFree = false,
  });

  @override
  State<VideoPage> createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage> {
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
  int totalSeconds = 1;
  double progress = 0;

  bool completedSent = false;

  bool progressSaved = false;
  bool savingNow = false;

  bool askedResume = false;
  bool initializedOnce = false;

  final commentController = TextEditingController();
  DateTime? lastCommentTime;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    Future.microtask(init);
  }

  @override
  void dispose() {
    try {
      saveLastPosition(currentSecond);
    } catch (_) {}

    try {
      videoController?.removeListener(listener);
    } catch (_) {}

    try {
      videoController?.dispose();
      videoController = null;

      chewieController?.dispose();
      chewieController = null;

      try {
        youtubeController?.close();
      } catch (_) {}
      youtubeController = null;

      try {
        audioPlayer?.dispose();
      } catch (_) {}
      audioPlayer = null;
    } catch (e) {
      debugPrint("Dispose Error: $e");
    }

    commentController.dispose();
    super.dispose();
  }

  Future init() async {
    if (initializedOnce) return;
    initializedOnce = true;

    await checkAccess();

    if (!hasAccess) {
      if (mounted) setState(() => loading = false);
      return;
    }

    await initVideo();

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future checkAccess() async {
    try {
      var user = FirebaseService.auth.currentUser;

      if (user == null) {
        hasAccess = widget.isFree;
        return;
      }

      var data = await FirebaseService.getUserData();

      bool isAdmin = data['isAdmin'] ?? false;
      bool subscribed = data['subscribed'] ?? false;
      isBlocked = data['blocked'] ?? false;

      String? endDate = data['subscriptionEnd'];

      bool valid =
          DateTime.tryParse(endDate ?? "")?.isAfter(DateTime.now()) ?? false;

      List unlocked = data['unlockedCourses'] ?? [];

      var courseDoc = await FirebaseService.firestore
          .collection(AppConstants.courses)
          .doc(widget.courseId)
          .get();

      bool courseFree = courseDoc.data()?['isFree'] == true;

      hasAccess = !isBlocked &&
          (isAdmin ||
              widget.isFree ||
              courseFree ||
              (subscribed && valid) ||
              unlocked.contains(widget.courseId));
    } catch (e) {
      debugPrint("Access Error: $e");
      hasAccess = widget.isFree;
    }
  }

  String _extractYoutubeId(String url) {
    try {
      final converted = YoutubePlayerController.convertUrlToId(url);
      if (converted != null && converted.isNotEmpty) {
        return converted;
      }
    } catch (_) {}

    final uri = Uri.tryParse(url);
    if (uri == null) return "";

    final host = uri.host.toLowerCase();

    if (host.contains("youtu.be") && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    if (uri.queryParameters.containsKey("v")) {
      return uri.queryParameters["v"] ?? "";
    }

    if (uri.pathSegments.contains("shorts")) {
      final index = uri.pathSegments.indexOf("shorts");
      if (index + 1 < uri.pathSegments.length) {
        return uri.pathSegments[index + 1];
      }
    }

    if (uri.pathSegments.contains("embed")) {
      final index = uri.pathSegments.indexOf("embed");
      if (index + 1 < uri.pathSegments.length) {
        return uri.pathSegments[index + 1];
      }
    }

    return "";
  }

  Future initVideo() async {
    String url = widget.videoUrl.trim();

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
      } catch (e) {
        debugPrint("🔥 Audio init error: $e");
        videoError = true;
      }

      return;
    }

    if (lowerUrl.contains("youtube") || lowerUrl.contains("youtu.be")) {
      isYoutube = true;

      String id = _extractYoutubeId(url);

      if (id.isEmpty) {
        videoError = true;
        return;
      }

      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
      );
      return;
    }

    url = "$url?v=${DateTime.now().millisecondsSinceEpoch}";

    try {
      videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await videoController!.initialize();

      await handleResume();

      chewieController = ChewieController(
        videoPlayerController: videoController!,
        autoPlay: true,
        allowFullScreen: true,
      );

      videoController!.addListener(listener);
    } catch (e) {
      videoError = true;
    }
  }

  Future handleResume() async {
    if (askedResume) return;
    askedResume = true;

    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null || videoController == null) return;

      var doc = await FirebaseService.firestore
          .collection(AppConstants.progress)
          .doc("${user.uid}_${widget.lessonId}")
          .get();

      if (!doc.exists) return;

      int sec = doc.data()?['watchedSeconds'] ?? 0;
      if (sec < 5) return;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.black,
          title: const Text("استكمال المشاهدة؟",
              style: TextStyle(color: Colors.white)),
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
    } catch (e) {
      debugPrint("Resume Error: $e");
    }
  }

  void listener() {
    if (videoController == null) return;

    final value = videoController!.value;

    if (!value.isInitialized) return;

    currentSecond = value.position.inSeconds;

    final duration = value.duration;

    if (duration.inSeconds <= 0) return;

    totalSeconds = duration.inSeconds;

    // 🚫 منع الغش
    if (currentSecond > maxWatchedSecond + 10) {
      videoController!.seekTo(Duration(seconds: maxWatchedSecond));
      return;
    }

    if (currentSecond > maxWatchedSecond) {
      maxWatchedSecond = currentSecond;
    }

    progress = maxWatchedSecond / totalSeconds;

    // 💾 حفظ كل 5 ثواني
    if (currentSecond % 5 == 0 && !savingNow) {
      savingNow = true;
      saveLastPosition(currentSecond).then((_) {
        savingNow = false;
      });
    }

    // 🎯 completion
    if (progress >= 0.9 && !completedSent) {
      completedSent = true;
      saveProgress();
      _markCompleted();
    }
  }

  Future saveLastPosition(int sec) async {
    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection(AppConstants.lastWatch)
          .doc("${user.uid}${widget.lessonId}")
          .set({
        "position": sec,
        "courseId": widget.courseId,
        "lessonId": widget.lessonId,
        "userId": user.uid,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Save Position Error: $e");
    }
  }

  Future saveProgress() async {
    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection(AppConstants.progress)
          .doc("${user.uid}_${widget.lessonId}")
          .set({
        "userId": user.uid,
        "courseId": widget.courseId,
        "lessonId": widget.lessonId,
        "watchedSeconds": maxWatchedSecond,
        "totalSeconds": totalSeconds,
        "progress": progress,
        "completed": progress >= 0.9,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Save Progress Error: $e");
    }
  }

  Future<void> _markCompleted() async {
    try {
      var user = FirebaseService.auth.currentUser;
      if (user == null) return;

      await FirebaseService.addXP(AppConstants.xpPerLesson);

      await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .set({
        "lastCompletedLesson": widget.lessonId,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Complete Error: $e");
    }
  }

  Future sendComment() async {
    var user = FirebaseService.auth.currentUser;
    if (user == null) return;

    String text = commentController.text.trim();
    if (text.isEmpty) return;

    if (lastCommentTime != null &&
        DateTime.now().difference(lastCommentTime!).inSeconds < 5) {
      return;
    }

    lastCommentTime = DateTime.now();

    await FirebaseService.firestore.collection(AppConstants.comments).add({
      "lessonId": widget.lessonId,
      "courseId": widget.courseId,
      "userId": user.uid,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return videoSafe(
      Scaffold(
        backgroundColor: AppColors.background,
        body: hasAccess
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildContent(),
                        ),
                        Positioned(
                          top: 40,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 15,
                          right: 15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: maxWatchedSecond > 0
                                    ? maxWatchedSecond /
                                        (videoController?.value.duration
                                                    .inSeconds ==
                                                0
                                            ? 1
                                            : videoController?.value.duration
                                                    .inSeconds ??
                                                1)
                                    : 0,
                                color: Colors.red,
                                backgroundColor: Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "اكتب تعليق...",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: AppColors.goldButton,
                            onPressed: sendComment,
                            child: const Text("إرسال"),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseService.firestore
                                .collection(AppConstants.comments)
                                .where('lessonId', isEqualTo: widget.lessonId)
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              var docs = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, i) {
                                  var d = docs[i];

                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(d['text'] ?? "",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : _lockedView(),
      ),
    );
  }

  Widget _buildContent() {
    if (videoError) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("❌ حدث خطأ في تشغيل المحتوى",
            style: TextStyle(color: Colors.white)),
      );
    }

    if (isPdf && widget.videoUrl.isNotEmpty) {
      return SfPdfViewer.network(widget.videoUrl);
    }

    if (isAudio && audioPlayer != null) {
      return Column(
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 50),
            onPressed: () {
              audioPlayer!.play();
            },
          ),
          IconButton(
            icon: const Icon(Icons.pause, size: 50),
            onPressed: () {
              audioPlayer!.pause();
            },
          ),
        ],
      );
    }

    if (isYoutube && youtubeController != null && mounted) {
      return YoutubePlayerScaffold(
        controller: youtubeController!,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return player;
        },
      );
    }

    if (videoController != null &&
        videoController!.value.isInitialized &&
        chewieController != null) {
      return AspectRatio(
        aspectRatio: videoController!.value.aspectRatio,
        child: Chewie(controller: chewieController!),
      );
    }

    if (videoError) {
      return const Center(
        child:
            Text("❌ فشل تحميل المحتوى", style: TextStyle(color: Colors.white)),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _lockedView() {
    return const Center(
      child: Text("🔒 محتاج اشتراك"),
    );
  }
}
