import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.scaleValue = 0.94,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  double scale = 1;
  double opacity = 1;
  bool hovered = false;
  bool pressed = false;

  late AnimationController _controller;
  late Animation<double> _elevation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _elevation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  void _updateState() {
    if (!mounted) return;

    double targetScale = 1;

    if (pressed) {
      targetScale = widget.scaleValue;
      _controller.reverse();
    } else if (hovered) {
      targetScale = 1.06;
      _controller.forward();
    } else {
      _controller.reverse();
    }

    setState(() {
      scale = targetScale;
      opacity = pressed ? 0.88 : 1;
    });
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    pressed = true;
    _updateState();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    pressed = false;
    _updateState();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    pressed = false;
    _updateState();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    pressed = false;
    _updateState();
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (!widget.enabled) return;
        hovered = true;
        _updateState();
      },
      onExit: (_) {
        if (!widget.enabled) return;
        hovered = false;
        pressed = false;
        _updateState();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _elevation,
          builder: (context, _) {
            return AnimatedScale(
              scale: scale,
              duration: widget.duration,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: opacity,
                child: RepaintBoundary(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      ..translate(0.0, hovered ? -4.0 - (_elevation.value * 4) : 0.0),
                    decoration: BoxDecoration(
                      boxShadow: hovered
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: 0.2 + (_elevation.value * 0.2)),
                                blurRadius: 20 + (_elevation.value * 15),
                                spreadRadius: _elevation.value * 2,
                                offset: Offset(0, 8 + (_elevation.value * 10)),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: widget.enabled ? _handleTap : null,
                        onTapDown: _onTapDown,
                        onTapCancel: _onTapCancel,
                        onTapUp: _onTapUp,
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        highlightColor: Colors.white.withValues(alpha: 0.04),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}