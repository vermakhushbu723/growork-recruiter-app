import 'package:flutter/material.dart';

/// A premium, "alive" icon badge — a soft glow halo breathes behind a
/// gradient-filled circle. Each instance can be given a [delay] so a row
/// of badges doesn't pulse in perfect lockstep.
class AnimatedIconBadge extends StatefulWidget {
  const AnimatedIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Duration delay;

  @override
  State<AnimatedIconBadge> createState() => _AnimatedIconBadgeState();
}

class _AnimatedIconBadgeState extends State<AnimatedIconBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + t * 0.4,
                child: Opacity(
                  opacity: (1 - t) * 0.35,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1 + t * 0.07,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.color.withValues(alpha: 0.24),
                        widget.color.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: widget.size * 0.42,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
