import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ItemsViewStock extends StatefulWidget {
  const ItemsViewStock({super.key});

  @override
  State<ItemsViewStock> createState() => _ItemsViewStockState();
}

class _ItemsViewStockState extends State<ItemsViewStock> {
  @override
  void initState() {
    super.initState();
    // Load user data when the page is initialized, if necessary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userData == null && !authProvider.isLoading) {
        authProvider.loadUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de Usuario - Stock'),
      ),
      body: _buildBody(context, authProvider),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
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
    if (authProvider.userData == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos del usuario'),
      );
    }
    
    final userData = authProvider.userData!;
    
    // Display raw user data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos del Usuario (Raw)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataRow('Nombre Completo', userData.nombreCompleto),
                  _buildDataRow('Código Usuario', userData.codUsuario.toString()),
                  _buildDataRow('Login', userData.login),
                  _buildDataRow('Cargo', userData.cargo ?? 'No especificado'),
                  _buildDataRow('Tipo Usuario', userData.tipoUsuario),
                  _buildDataRow('Código Empresa', userData.codEmpresa.toString()),
                  _buildDataRow('Código ciudad', userData.codCiudad.toString()),
               
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Esta vista muestra los datos crudos del usuario obtenidos a través del AuthProvider',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}