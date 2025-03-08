import 'package:app_ipx_esp_ddd/presentation/widgets/dashboard/expandible_menu.dart';
import 'package:app_ipx_esp_ddd/presentation/pages/login_page.dart';
import 'package:app_ipx_esp_ddd/presentation/providers/view_provider.dart';
import 'package:app_ipx_esp_ddd/domain/models/vista.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  
  // Override to ensure the widget is considered constant
  @override
  // ignore: invalid_override_of_non_virtual_member
  bool operator ==(Object other) {
    return other is DashboardPage && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => 0; // A constant value since the widget has no properties

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedOption = 'Inicio';
  final int _selectedIndex = 0;
  Vista? _selectedMenuItem;
  String _currentContent = 'Bienvenido al Dashboard';
  
  @override
  void initState() {
    super.initState();
    // Load user data when the page is initialized, only if necessary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userData == null && !authProvider.isLoading) {
        authProvider.loadUserData();
      }
      
      // Load menu if we have the user
      if (authProvider.userData != null) {
        Provider.of<MenuProvider>(context, listen: false)
          .loadMenu(authProvider.userData!.codUsuario);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final userData = authProvider.userData;
    
    return WillPopScope(
      onWillPop: () async {
        // Don't allow going back with the back button
        // Instead, show a dialog to confirm exit
        final shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedOption),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notificaciones',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay notificaciones nuevas'))
                );
              },
            ),
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
                accountName: Text(
                  userData?.nombreCompleto ?? 'Cargando...', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                accountEmail: Text(
                  userData?.cargo ?? '',
                  style: const TextStyle(fontSize: 14)
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    userData != null && userData.nombreCompleto.isNotEmpty
                      ? userData.nombreCompleto.trim().split(' ')[0][0].toUpperCase()
                      : 'U',
                    style: TextStyle(
                      fontSize: 40.0, 
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                otherAccountsPictures: [
                  if (userData != null)
                    Tooltip(
                      message: 'Sucursal ${userData.codSucursal}',
                      child: CircleAvatar(
                        backgroundColor: Colors.white70,
                        child: Text(
                          'S${userData.codSucursal}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Show loader while menu is loading
              if (menuProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              // Show error if there were problems loading the menu
              if (menuProvider.error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Error: ${menuProvider.error}', 
                        style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: () {
                          if (userData != null) {
                            menuProvider.loadMenu(userData.codUsuario);
                          }
                        },
                        child: const Text('Reintentar'),
                      )
                    ],
                  ),
                ),
              // Show expandable menu
              if (!menuProvider.isLoading && menuProvider.error == null && menuProvider.menuItems.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: ExpandableMenu(
                      menuItems: menuProvider.menuItems,
                      selectedItemId: _selectedMenuItem?.codVista,
                      onItemSelected: (item) {
                        setState(() {
                          _selectedMenuItem = item;
                          _selectedOption = item.label ?? "Sin título";
                          if (item.routerLink != null) {
                            _currentContent = 'Navegando a: ${item.routerLink}';
                          } else {
                            _currentContent = 'Sección: ${item.label ?? ""}';
                          }
                        });
                        Navigator.pop(context); // Close drawer
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        body: _buildBody(context, authProvider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
    final userData = authProvider.userData;
    
    // If loading, show indicator
    if (authProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // If there's an error, show message
    if (authProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${authProvider.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).loadUserData();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    // If no user data, show message
    if (userData == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos del usuario'),
      );
    }
    
    // If a menu item has been selected
    if (_selectedMenuItem != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon based on section
            Icon(_getIconForSection(), size: 60, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              _selectedOption,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedMenuItem!.routerLink != null)
              Text(
                'Ruta: ${_selectedMenuItem!.routerLink}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 24),
            const Text(
              'Aquí se cargará el contenido de la sección seleccionada',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Default content if nothing has been selected
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${_getFirstName(userData.nombreCompleto)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 24),
          
          // Information cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInfoCard(
                'Empresa', 
                '${userData.codEmpresa}', 
                Icons.business, 
                Colors.blue
              ),
              _buildInfoCard(
                'Sucursal', 
                '${userData.codSucursal}', 
                Icons.store, 
                Colors.green
              ),
              _buildInfoCard(
                'Usuario', 
                userData.login, 
                Icons.person, 
                Colors.orange
              ),
              _buildInfoCard(
                'Rol', 
                userData.tipoUsuario, 
                Icons.badge, 
                Colors.purple
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Instrucciones', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Utiliza el menú lateral para navegar entre las diferentes secciones del sistema. Cada opción te llevará a un módulo distinto donde podrás realizar las operaciones correspondientes.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Para abrir el menú, desliza desde el borde izquierdo de la pantalla o toca el ícono de menú en la esquina superior izquierda.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForSection() {
    if (_selectedMenuItem == null) return Icons.home;
    
    // Determine icon based on section name
    final label = _selectedMenuItem!.label?.toLowerCase() ?? "";
    
    if (label.contains('rrhh') || label.contains('recursos') || label.contains('empleado')) {
      return Icons.people;
    } else if (label.contains('admin') || label.contains('configuración')) {
      return Icons.settings;
    } else if (label.contains('venta') || label.contains('factura')) {
      return Icons.receipt;
    } else if (label.contains('compra')) {
      return Icons.shopping_cart;
    } else if (label.contains('reporte')) {
      return Icons.bar_chart;
    } else if (label.contains('precio')) {
      return Icons.attach_money;
    } else if (label.contains('comisi')) {
      return Icons.monetization_on;
    } else if (label.contains('pedido')) {
      return Icons.assignment;
    } else if (label.contains('tarea')) {
      return Icons.check_circle;
    } else if (label.contains('producci')) {
      return Icons.precision_manufacturing;
    } else if (label.contains('santa cruz')) {
      return Icons.location_on;
    } else if (label.contains('material')) {
      return Icons.inventory;
    } else if (label.contains('entrega')) {
      return Icons.local_shipping;
    } else if (label.contains('vehículo')) {
      return Icons.directions_car;
    } else if (label.contains('licitaci')) {
      return Icons.gavel;
    } else if (label.contains('ficha')) {
      return Icons.badge;
    } else if (label.contains('depósito')) {
      return Icons.account_balance;
    }
    
    return Icons.article;
  }
  
  String _getFirstName(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return '';
    return nombreCompleto.trim().split(' ')[0];
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
                  // Get reference to authentication provider
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  // Make sure to completely close the session
                  await authProvider.logout();
                  
                  if (context.mounted) {
                    // First close the dialog
                    Navigator.of(context).pop();
                    
                    // Restart the application or navigate to login with a more drastic approach
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', 
                      (_) => false,  // This removes all previous routes
                    );
                  }
                } catch (e) {
                  // If there's any error during the process, force navigation to login
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
  
  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la aplicación?'),
        content: const Text('¿Estás seguro que deseas salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}