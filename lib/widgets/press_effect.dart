// 🔥 PRESS EFFECT (FIXED + WEB SAFE + CLICK ALWAYS WORKS)

import 'package:flutter/material.dart';

class PressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  final bool enabled;
  final double scaleValue;
  final Duration duration;

  const PressEffect({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.scaleValue = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect> {
  double scale = 1;
  double opacity = 1;

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() {
      scale = widget.scaleValue;
      opacity = 0.9;
    });
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    setState(() {
      scale = 1;
      opacity = 1;
    });
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    setState(() {
      scale = 1;
      opacity = 1;
    });
  }

  void _handleTap() {
    if (!widget.enabled) return;
    setState(() {
      scale = 1;
      opacity = 1;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,

        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOut,

          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: opacity,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}