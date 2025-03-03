import 'package:flutter/material.dart';

/// Clase para gestionar animaciones en menús y elementos navegables
class MenuAnimation {
  /// Crear una animación de entrada para ítems
  static Animation<double> createFadeInAnimation(
    AnimationController controller, {
    double from = 0.0,
    double to = 1.0,
    Curve curve = Curves.easeOut,
  }) {
    return Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  /// Crear una animación de deslizamiento
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(-0.05, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  /// Animar la rotación de un ícono expandible
  static Widget animatedExpandIcon({
    required bool isExpanded,
    required IconData icon,
    required Color color,
    double size = 12.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCirc,
  }) {
    return AnimatedRotation(
      turns: isExpanded ? 0.25 : 0,
      duration: duration,
      curve: curve,
      child: Icon(icon, size: size, color: color),
    );
  }

  /// Crear una secuencia de animaciones para un efecto complejo
  static TweenSequence<double> createSequencedAnimation({
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: begin, end: end * 0.7),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: end * 0.7, end: end),
        weight: 0.6,
      ),
    ]);
  }
  
  /// Generar retraso incremental para animaciones en cascada
  static Duration cascadeDelay(int index, {int baseMs = 50}) {
    return Duration(milliseconds: baseMs * index);
  }
  
  /// Crear una animación de pulso para destacar elementos nuevos
  static Animation<double> createPulseAnimation(
    AnimationController controller, {
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: maxScale),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: maxScale, end: minScale),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: minScale, end: 1.0),
        weight: 0.3,
      ),
    ]).animate(controller);
  }
}
