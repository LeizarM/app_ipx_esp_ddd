import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:simple_animations/simple_animations.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;
  final Color color1;
  final Color color2;

  const LiquidBackground({
    super.key,
    required this.child,
    this.color1 = const Color(0xFF1565C0),
    this.color2 = const Color(0xFF0D47A1),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBackground(color1: color1, color2: color2),
        ),
        Positioned.fill(
          child: AnimatedWaves(),
        ),
        child,
      ],
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  final Color color1;
  final Color color2;

  const AnimatedBackground({
    super.key,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 20),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
              stops: [value, value + 0.5],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedWaves extends StatelessWidget {
  const AnimatedWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 15),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return CustomPaint(
          painter: WavesPainter(animationValue: value),
        );
      },
    );
  }
}

class WavesPainter extends CustomPainter {
  final double animationValue;

  WavesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path1 = _createWavePath(size, animationValue, 1.0);
    final path2 = _createWavePath(size, animationValue - 0.5, 1.5);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint..color = Colors.white.withOpacity(0.05));
  }

  Path _createWavePath(Size size, double value, double intensity) {
    final path = Path();
    final waveHeight = size.height / 10 * intensity;
    final waveCount = 4;

    path.moveTo(0, size.height / 2);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final normalizedX = x / size.width;
      final offset = math.sin((normalizedX + value) * waveCount * math.pi * 2) *
          waveHeight;
      final y = size.height / 2 + offset;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
