// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'presentation/middleware/auth_middleware.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart'; // Added import for dashboard
import 'presentation/providers/auth_provider.dart';

void main() {
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Usar una key para recrear el AuthProvider al cerrar sesión
        ChangeNotifierProvider(
          key: const ValueKey('auth_provider'),
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IPX - ESP',
        theme: _buildAppTheme(),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const DashboardPage(),
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
    
    // If you want to use the purple-green theme instead, comment out the above return
    // and uncomment the following:
    // return PurpleGreenTheme.theme;
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