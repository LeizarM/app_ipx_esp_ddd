import 'package:flutter/material.dart';
import 'dart:math' show pi;

class RotatingCube extends StatefulWidget {
  final double size;
  final Color color;

  const RotatingCube({
    super.key,
    this.size = 60.0,
    required this.color,
  });

  @override
  State<RotatingCube> createState() => _RotatingCubeState();
}

class _RotatingCubeState extends State<RotatingCube>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
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
      builder: (_, __) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_controller.value * 2 * pi)
            ..rotateY(_controller.value * 2 * pi),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CubePainter(color: widget.color),
          ),
        );
      },
    );
  }
}

class CubePainter extends CustomPainter {
  final Color color;

  CubePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Front face
    path.moveTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.close();

    // Top face
    final topPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..close();

    // Right face
    final rightPath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.6)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(topPath, paint..color = color.withOpacity(0.8));
    canvas.drawPath(rightPath, paint..color = color.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
