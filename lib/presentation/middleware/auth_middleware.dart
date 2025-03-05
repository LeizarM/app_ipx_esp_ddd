// lib/presentation/middleware/auth_middleware.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/di/service_locator.dart';

class AuthMiddleware extends StatefulWidget {
  final Widget child;

  const AuthMiddleware({
    super.key,
    required this.child,
  });

  @override
  State<AuthMiddleware> createState() => _AuthMiddlewareState();
}

class _AuthMiddlewareState extends State<AuthMiddleware> {
  bool _isVerifying = true;
  final AuthRepository _authRepository = getIt<AuthRepository>();

  @override
  void initState() {
    super.initState();
    _verifyTokenValidity();
  }

  /// Verifica activamente la validez del token
  Future<void> _verifyTokenValidity() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // Verificar si el token es válido
      final isTokenValid = await _authRepository.refreshTokenIfNeeded();

      // Si el token no es válido, cerrar sesión
      if (!isTokenValid && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
      }
    } catch (e) {
      print('Error verificando token en middleware: $e');
      // En caso de error, también cerrar sesión
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
      }
    } finally {
      // Actualizar estado si el widget sigue montado
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos verificando, mostrar indicador de carga
    if (_isVerifying) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Ya no estamos verificando, usar el Consumer para verificar autenticación
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si no está autenticado, redireccionar al login
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }
        
        // Todo en orden, mostrar el widget hijo
        return widget.child;
      },
    );
  }
}