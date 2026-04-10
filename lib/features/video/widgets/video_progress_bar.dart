import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class VideoProgressBar extends StatefulWidget {
  final int watched;
  final int total;
  final Function(double value)? onSeek;

  const VideoProgressBar({
    super.key,
    required this.watched,
    required this.total,
    this.onSeek,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {

  double localValue = 0;
  bool isDragging = false;

  String formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;

    if (widget.total > 0) {
      progress = widget.watched / widget.total;
    }

    if (!isDragging) {
      localValue = progress.clamp(0, 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          color: AppColors.gold,
          backgroundColor: Colors.white24,
          minHeight: 6,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: localValue.clamp(0, 1),
            onChangeStart: widget.total > 0
                ? (value) {
                    isDragging = true;
                  }
                : null,
            onChanged: widget.total > 0
                ? (value) {
                    setState(() {
                      localValue = value;
                    });
                  }
                : null,
            onChangeEnd: widget.total > 0
                ? (value) {
                    isDragging = false;
                    if (widget.onSeek != null) {
                      widget.onSeek!(value);
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${formatTime(widget.watched)} / ${formatTime(widget.total)}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        )
      ],
    );
  }
}