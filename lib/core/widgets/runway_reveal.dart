import 'package:flutter/material.dart';

class RunwayReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final bool slideUp;

  const RunwayReveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.slideUp = true,
  });

  @override
  State<RunwayReveal> createState() => _RunwayRevealState();
}

class _RunwayRevealState extends State<RunwayReveal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    // "Take-off" motion: starts lower and slides up, or slides in from side?
    // Prompt says "ascending motion, like an aircraft lifting".
    _slideAnimation = Tween<Offset>(
      begin: widget.slideUp ? const Offset(0, 0.2) : const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
