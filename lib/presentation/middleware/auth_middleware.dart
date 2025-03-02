// lib/presentation/middleware/auth_middleware.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/auth/auth_service.dart';
import '../../core/di/service_locator.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';

class AuthMiddleware extends StatelessWidget {
  final Widget child;

  const AuthMiddleware({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Verificar autenticación con un enfoque más directo
        // Si isAuthenticated es false, redireccionar inmediatamente
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }
        
        // Solo mostrar el child si está autenticado
        return child;
      },
    );
  }
}