import 'package:flutter/material.dart';

class ForestLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const ForestLogo({
    super.key,
    this.size = 120.0,
    this.primaryColor = Colors.white,
    this.secondaryColor = const Color(0xFF81C784),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo circular
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          
          // Árbol principal
          Positioned(
            bottom: size * 0.15,
            child: _buildTree(
              height: size * 0.65,
              width: size * 0.35,
              color: primaryColor,
              trunkColor: secondaryColor.withOpacity(0.8),
            ),
          ),
          
          // Árbol izquierdo
          Positioned(
            bottom: size * 0.15,
            left: size * 0.15,
            child: _buildTree(
              height: size * 0.55,
              width: size * 0.3,
              color: primaryColor.withOpacity(0.9),
              trunkColor: secondaryColor.withOpacity(0.7),
            ),
          ),
          
          // Árbol derecho
          Positioned(
            bottom: size * 0.15,
            right: size * 0.15,
            child: _buildTree(
              height: size * 0.5,
              width: size * 0.28,
              color: primaryColor.withOpacity(0.85),
              trunkColor: secondaryColor.withOpacity(0.75),
            ),
          ),
          
          // Árbol pequeño izquierdo
          Positioned(
            bottom: size * 0.15,
            left: size * 0.02,
            child: _buildTree(
              height: size * 0.4,
              width: size * 0.22,
              color: primaryColor.withOpacity(0.7),
              trunkColor: secondaryColor.withOpacity(0.6),
            ),
          ),
          
          // Árbol pequeño derecho
          Positioned(
            bottom: size * 0.15,
            right: size * 0.02,
            child: _buildTree(
              height: size * 0.45,
              width: size * 0.24,
              color: primaryColor.withOpacity(0.75),
              trunkColor: secondaryColor.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTree({
    required double height,
    required double width,
    required Color color,
    required Color trunkColor,
  }) {
    final triangleHeight = height * 0.7;
    final trunkHeight = height - triangleHeight;
    final trunkWidth = width * 0.2;
    
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Tronco
          Positioned(
            bottom: 0,
            child: Container(
              width: trunkWidth,
              height: trunkHeight,
              decoration: BoxDecoration(
                color: trunkColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(trunkWidth * 0.2)),
              ),
            ),
          ),
          
          // Hojas (triángulo)
          Positioned(
            bottom: trunkHeight * 0.8,
            child: ClipPath(
              clipper: TriangleClipper(),
              child: Container(
                width: width,
                height: triangleHeight,
                color: color,
              ),
            ),
          ),
          
          // Segunda capa de hojas
          Positioned(
            bottom: trunkHeight * 0.8 + triangleHeight * 0.3,
            child: ClipPath(
              clipper: TriangleClipper(),
              child: Container(
                width: width * 0.8,
                height: triangleHeight * 0.75,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0); // Punta
    path.lineTo(0, size.height);     // Esquina inferior izquierda
    path.lineTo(size.width, size.height); // Esquina inferior derecha
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
