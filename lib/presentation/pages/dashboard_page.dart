import 'package:app_ipx_esp_ddd/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/menu_item.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedOption = 'Inicio';
  
  // Ejemplo de ítems del menú - en producción deberían venir de un servicio
  final List<CustomMenuItem> _menuItems = [
    CustomMenuItem(
      title: 'Inicio',
      icon: Icons.home,
      route: '/dashboard',
    ),
    CustomMenuItem(
      title: 'Perfil',
      icon: Icons.person,
      route: '/profile',
    ),
    CustomMenuItem(
      title: 'Configuración',
      icon: Icons.settings,
      route: '/settings',
    ),
    // Aquí se añadirían más opciones según el rol del usuario
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedOption),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Nombre de Usuario'),
              accountEmail: const Text('usuario@ejemplo.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'U',
                  style: TextStyle(fontSize: 40.0, color: Theme.of(context).primaryColor),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    selected: _selectedOption == item.title,
                    onTap: () {
                      setState(() {
                        _selectedOption = item.title;
                      });
                      Navigator.pop(context); // Cierra el drawer
                      // Aquí se implementaría la navegación real
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenido al Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text('Sección actual: $_selectedOption'),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Obtener la referencia al provider de autenticación
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  // Asegurarnos de cerrar completamente la sesión
                  await authProvider.logout();
                  
                  if (context.mounted) {
                    // Primero cerrar el diálogo
                    Navigator.of(context).pop();
                    
                    // Reiniciar la aplicación o navegar a login con un enfoque más drástico
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', 
                      (_) => false,  // Esto remueve todas las rutas anteriores
                    );
                  }
                } catch (e) {
                  // Si hay algún error durante el proceso, forzar la navegación al login
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false
                    );
                  }
                }
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}