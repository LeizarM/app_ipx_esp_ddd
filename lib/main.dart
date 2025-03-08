// lib/main.dart
import 'package:app_ipx_esp_ddd/application/articulo_propuesto/articulo_propuesto_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'presentation/middleware/auth_middleware.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/view_provider.dart'; // Importar el servicio de artículos
import 'dart:async';
import 'domain/repositories/auth_repository.dart';

// El navigatorKey ya está definido en service_locator.dart

void main() {
  // Configuración de manejo de errores no capturados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _tokenValidationTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Iniciar validación periódica de tokens
    _startTokenValidation();
  }
  
  @override
  void dispose() {
    // Limpiar timer al desmontar
    _tokenValidationTimer?.cancel();
    super.dispose();
  }
  
  // Iniciar validación periódica de token
  void _startTokenValidation() {
    // Cancelar timer existente si hay alguno
    _tokenValidationTimer?.cancel();
    
    // Crear un nuevo timer que valide el token cada cierto tiempo
    _tokenValidationTimer = Timer.periodic(
      const Duration(minutes: 5), // Validar cada 5 minutos
      (_) => _validateToken()
    );
  }
  
  // Validar token periódicamente
  Future<void> _validateToken() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final isValid = await authRepository.refreshTokenIfNeeded();
      
      if (!isValid) {
        // Si el token no es válido, redirigir al login
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          
          await authProvider.logout();
          
          // Navegar al login después de cerrar sesión
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        }
      }
    } catch (e) {
      print('Error al validar token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Usar una key para recrear el AuthProvider al cerrar sesión
        ChangeNotifierProvider(
          key: const ValueKey('auth_provider'),
          create: (_) => AuthProvider(),
        ),
        // Añadimos el MenuProvider
        ChangeNotifierProvider(
          key: const ValueKey('menu_provider'),
          create: (_) => MenuProvider(),
        ),
        // Añadimos el Provider para ArticuloService
        Provider<ArticuloService>(
          create: (_) => getIt<ArticuloService>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IPX - ESP',
        theme: _buildAppTheme(),
        navigatorKey: navigatorKey, // Usar la llave global
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const AuthMiddleware(
            child: DashboardPage(),
          ),
          // Otras rutas...
        },
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading indicator while checking authentication
            if (authProvider.isLoading) {
              return _buildLoadingScreen();
            }
            
            // Navigate based on authentication status
            return authProvider.isAuthenticated
                ? _buildAuthenticatedRoute()
                : const LoginPage();
          },
        ),
      ),
    );
  }

  // Separate method for theme configuration
  ThemeData _buildAppTheme() {
    // Default theme
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    );
  }

  // Loading screen widget
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Route for authenticated users
  Widget _buildAuthenticatedRoute() {
    return AuthMiddleware(
      child: const DashboardPage(),
    );
  }
}