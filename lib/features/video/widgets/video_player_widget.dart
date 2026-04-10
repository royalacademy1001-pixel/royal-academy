import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:just_audio/just_audio.dart';

class VideoPlayerWidget extends StatelessWidget {
  final bool videoError;
  final bool isPdf;
  final bool isAudio;
  final bool isYoutube;

  final String videoUrl;

  final ChewieController? chewieController;
  final YoutubePlayerController? youtubeController;
  final AudioPlayer? audioPlayer;

  const VideoPlayerWidget({
    super.key,
    required this.videoError,
    required this.isPdf,
    required this.isAudio,
    required this.isYoutube,
    required this.videoUrl,
    required this.chewieController,
    required this.youtubeController,
    required this.audioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (videoError) {
      return const Center(
        child: Text(
          "❌ حدث خطأ في تشغيل المحتوى",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (isPdf && videoUrl.isNotEmpty) {
      return SizedBox(
        height: 500,
        child: SfPdfViewer.network(videoUrl),
      );
    }

    if (isAudio && audioPlayer != null) {
      return Column(
        children: [
          StreamBuilder<Duration>(
            stream: audioPlayer!.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data?.inSeconds ?? 0;
              return Text(
                "$position s",
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
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

    if (isYoutube && youtubeController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: youtubeController!,
        ),
      );
    }

    if (chewieController != null &&
        chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio:
            chewieController!.videoPlayerController.value.aspectRatio == 0
                ? 16 / 9
                : chewieController!.videoPlayerController.value.aspectRatio,
        child: Chewie(controller: chewieController!),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}