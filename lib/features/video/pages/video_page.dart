import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../controller/video_controller.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_comments.dart';
import '../widgets/video_progress_bar.dart';

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
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {

  late VideoController controller;
  bool isMini = false;

  @override
  void initState() {
    super.initState();

    controller = VideoController(
      videoUrl: widget.videoUrl,
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      isFree: widget.isFree,
    );

    init();
  }

  Future<void> init() async {
    await controller.checkAccess();

    if (!controller.hasAccess) {
      if (!mounted) return;
      setState(() => controller.loading = false);
      return;
    }

    await controller.initVideo(context);

    if (!mounted) return;

    setState(() {
      controller.loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!controller.hasAccess) {
      return const Scaffold(
        body: Center(child: Text("🔒 محتاج اشتراك")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [

          Column(
            children: [

              if (!isMini)
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null &&
                        details.primaryDelta! < -10) {
                      setState(() => isMini = true);
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayerWidget(
                      videoError: controller.videoError,
                      isPdf: controller.isPdf,
                      isAudio: controller.isAudio,
                      isYoutube: controller.isYoutube,
                      videoUrl: widget.videoUrl,
                      chewieController: controller.chewieController,
                      youtubeController: controller.youtubeController,
                      audioPlayer: controller.audioPlayer,
                    ),
                  ),
                ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VideoProgressBar(
                        watched: controller.maxWatchedSecond,
                        total: controller.totalSeconds,
                        onSeek: (value) {
                          if (controller.videoController != null) {
                            final sec =
                                (value * controller.totalSeconds).toInt();
                            controller.videoController!
                                .seekTo(Duration(seconds: sec));
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: VideoComments(
                        courseId: widget.courseId,
                        lessonId: widget.lessonId,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),

          if (isMini)
            Positioned(
              bottom: 20,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() => isMini = false);
                },
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null &&
                      details.primaryDelta! > 10) {
                    setState(() => isMini = false);
                  }
                },
                child: Container(
                  width: 180,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayerWidget(
                      videoError: controller.videoError,
                      isPdf: controller.isPdf,
                      isAudio: controller.isAudio,
                      isYoutube: controller.isYoutube,
                      videoUrl: widget.videoUrl,
                      chewieController: controller.chewieController,
                      youtubeController: controller.youtubeController,
                      audioPlayer: controller.audioPlayer,
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}