import 'package:flutter/material.dart';
import 'dart:async';

class RadarAnimation extends StatefulWidget {
  final bool isAnimating; // Whether the animation should continue
  RadarAnimation({Key? key, required this.isAnimating}) : super(key: key);

  @override
  _RadarAnimationState createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isAnimating) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;
  RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.green.withOpacity(0.3) // Change this for color
      ..style = PaintingStyle.fill  // Use fill style for the circle
      ..strokeWidth = 2;

    double radius = size.width * animationValue;
    double opacity = 1 - animationValue; // Fade effect as the circle grows

    // Apply fading effect to the circle color based on the animation value
    paint.color = paint.color.withOpacity(opacity);

    // Draw the pulsing circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
