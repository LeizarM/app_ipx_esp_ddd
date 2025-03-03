import 'package:flutter/material.dart';

/// Clase para gestionar decoraciones visuales avanzadas para menús
class MenuDecoration {
  /// Crea una decoración de fondo para categorías principales
  static BoxDecoration categoryBackground(Color primaryColor, {double opacity = 0.15}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primaryColor.withOpacity(opacity),
          primaryColor.withOpacity(opacity * 0.4),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
    );
  }
  
  /// Crea una decoración para ítems seleccionados
  static BoxDecoration selectedItemDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.primaryContainer.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: colorScheme.primary.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        )
      ],
    );
  }
  
  /// Crea una decoración para ítems con hover
  static BoxDecoration hoveredItemDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.primaryContainer.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        )
      ],
    );
  }
  
  /// Crea una decoración para contenedores de íconos
  static BoxDecoration iconContainerDecoration(
    ColorScheme colorScheme, {
    bool isSelected = false, 
    bool isHovered = false
  }) {
    return BoxDecoration(
      color: isSelected
          ? colorScheme.primary.withOpacity(0.1)
          : isHovered
              ? colorScheme.primary.withOpacity(0.05)
              : colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(6),
    );
  }
  
  /// Crea una decoración para badges o contadores
  static BoxDecoration badgeDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.tertiary,
      borderRadius: BorderRadius.circular(10),
    );
  }
  
  /// Crea un degradado para separadores
  static LinearGradient dividerGradient(Color color) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color,
        color.withOpacity(0.5),
        color.withOpacity(0.3),
      ],
    );
  }
}
