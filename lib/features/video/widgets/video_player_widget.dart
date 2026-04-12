import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio/just_audio.dart' as ja;

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

    if (isPdf && videoUrl.trim().isNotEmpty) {
      return SizedBox(
        height: 500,
        child: SfPdfViewer.network(videoUrl.trim()),
      );
    }

    if (isAudio && audioPlayer != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<Duration?>(
            stream: audioPlayer!.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data?.inSeconds ?? 0;
              return Text(
                "$position s",
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 10),
          StreamBuilder<ja.PlayerState>(
            stream: audioPlayer!.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, size: 30),
                    onPressed: () async {
                      final pos = audioPlayer!.position.inSeconds - 10;
                      await audioPlayer!.seek(Duration(seconds: pos < 0 ? 0 : pos));
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      size: 50,
                    ),
                    onPressed: () async {
                      if (playing) {
                        await audioPlayer!.pause();
                      } else {
                        await audioPlayer!.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, size: 30),
                    onPressed: () async {
                      final pos = audioPlayer!.position.inSeconds + 10;
                      await audioPlayer!.seek(Duration(seconds: pos));
                    },
                  ),
                ],
              );
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
      final ratio =
          chewieController!.videoPlayerController.value.aspectRatio;

      return AspectRatio(
        aspectRatio: ratio <= 0 ? 16 / 9 : ratio,
        child: Chewie(controller: chewieController!),
      );
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}