import 'package:flutter/material.dart';  
import 'package:provider/provider.dart';  
import '../providers/auth_provider.dart';  
import 'dashboard_page.dart';
import '../widgets/liquid_background.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/forest_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
  
class LoginPage extends StatefulWidget {  
  const LoginPage({Key? key}) : super(key: key);  
 
  @override  
  _LoginPageState createState() => _LoginPageState();  
}  
 
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {  
  final _formKey = GlobalKey<FormState>();  
  final _usernameController = TextEditingController();  
  final _passwordController = TextEditingController();
  late AnimationController _staggeredController;
 
  @override
  void initState() {
    super.initState();
    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Iniciar animación después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggeredController.forward();
    });
  }
 
  @override  
  void dispose() {  
    _usernameController.dispose();  
    _passwordController.dispose();
    _staggeredController.dispose();
    super.dispose();  
  }  
 
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      body: LiquidBackground(
        color1: const Color(0xFF2962FF),
        color2: const Color(0xFF0D47A1),
        child: Consumer<AuthProvider>(  
          builder: (context, authProvider, _) {  
            if (authProvider.isAuthenticated) {  
              // Redirigir al dashboard si ya está autenticado  
              WidgetsBinding.instance.addPostFrameCallback((_) {  
                Navigator.of(context).pushReplacement(  
                  MaterialPageRoute(builder: (_) => const DashboardPage()),  
                );  
              });  
            }  
 
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reemplazar icono por logo de bosque personalizado
                        ForestLogo(
                          size: 150,
                          primaryColor: Colors.white,
                          secondaryColor: const Color(0xFF81C784),
                        )
                        .animate(controller: _staggeredController)
                        .scale(duration: 600.ms, curve: Curves.easeOut)
                        .fade(duration: 500.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Título
                        Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                        .animate(controller: _staggeredController)
                        .fade(duration: 500.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 300.ms, curve: Curves.easeOut),
                        
                        const SizedBox(height: 40),
                        
                        // Tarjeta del formulario
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(  
                            key: _formKey,  
                            child: Column(  
                              mainAxisSize: MainAxisSize.min,
                              children: [  
                                ModernTextField(  
                                  controller: _usernameController,
                                  label: 'Usuario',
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {  
                                    if (value == null || value.isEmpty) {  
                                      return 'Por favor ingrese su usuario';  
                                    }  
                                    return null;  
                                  },  
                                ).animate(controller: _staggeredController)
                                 .fade(duration: 500.ms, delay: 600.ms)
                                 .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOut),
                                
                                ModernTextField(  
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (value) {  
                                    if (value == null || value.isEmpty) {  
                                      return 'Por favor ingrese su contraseña';  
                                    }  
                                    return null;  
                                  },  
                                ).animate(controller: _staggeredController)
                                 .fade(duration: 500.ms, delay: 800.ms)
                                 .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 800.ms, curve: Curves.easeOut),
                                
                                const SizedBox(height: 24),
                                
                                if (authProvider.error != null)  
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            authProvider.error!,
                                            style: TextStyle(color: Colors.red.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate()
                                    .fade(duration: 300.ms)
                                    .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOut),
                                
                                const SizedBox(height: 24),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading  
                                        ? null  
                                        : () async {  
                                            if (_formKey.currentState!.validate()) {  
                                              // Uncomment this line to use debug login temporarily
                                              // final success = await authProvider.debugLogin(
                                              
                                              // Regular login
                                              final success = await authProvider.login(  
                                                _usernameController.text,  
                                                _passwordController.text,  
                                              );  
                                                
                                              if (success && mounted) {  
                                                Navigator.of(context).pushReplacement(  
                                                  MaterialPageRoute(  
                                                    builder: (_) => const DashboardPage(),  
                                                  ),  
                                                );  
                                              }  
                                            }  
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: authProvider.isLoading  
                                        ? const CircularProgressIndicator(color: Colors.white)  
                                        : const Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ).animate(controller: _staggeredController)
                                 .fade(duration: 500.ms, delay: 1000.ms)
                                 .scale(begin: const Offset(0.9, 0.9), duration: 500.ms, delay: 1000.ms),
                              ],  
                            ),  
                          ),
                        ).animate(controller: _staggeredController)
                         .fade(duration: 800.ms, delay: 400.ms)
                         .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms, curve: Curves.easeOut),
                      ],  
                    ),  
                  ),
                ),
              ),
            );  
          },  
        ),
      ),  
    );  
  }  
}