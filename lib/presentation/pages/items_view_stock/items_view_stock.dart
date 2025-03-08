import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import 'package:app_ipx_esp_ddd/application/articulo_propuesto/articulo_propuesto_service.dart';
import 'package:app_ipx_esp_ddd/domain/models/ArticuloPropuesto.dart';
import 'package:app_ipx_esp_ddd/core/di/service_locator.dart';
import 'package:app_ipx_esp_ddd/core/utils/token_utils.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'dart:math' as math;

class ItemsViewStock extends StatefulWidget {
  const ItemsViewStock({super.key});

  @override
  State<ItemsViewStock> createState() => _ItemsViewStockState();
}

class _ItemsViewStockState extends State<ItemsViewStock> {
  bool _isLoadingArticles = false;
  List<ArticuloPropuesto> _articulos = [];
  String? _articlesError;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Cargar datos de usuario cuando se inicializa la página, si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userData == null && !authProvider.isLoading) {
        authProvider.loadUserData();
      }
      
      // Cargar artículos una vez que los datos del usuario estén disponibles
      if (authProvider.userData != null) {
        _loadArticulos(authProvider.userData!.codCiudad);
      }
    });
  }
  
  // Cargar artículos usando el codCiudad del usuario
  Future<void> _loadArticulos(int codCiudad) async {
    setState(() {
      _isLoadingArticles = true;
      _articlesError = null;
    });
    
    try {
      // Obtener el repositorio de autenticación
      final authRepository = getIt<AuthRepository>();
      
      // Verificar y refrescar el token si es necesario antes de la petición
      final isTokenValid = await authRepository.refreshTokenIfNeeded();

      debugPrint('Token válido: $isTokenValid');

      if (!isTokenValid) {
        if (mounted) {
          _redirectToLogin();
        }
        return;
      }
      
      // Continuar con la petición de artículos
      final articuloService = Provider.of<ArticuloService>(context, listen: false);
      final articulos = await articuloService.getArticulosxCity(codCiudad);
      
      if (mounted) {
        setState(() {
          _articulos = articulos;
          _isLoadingArticles = false;
        });
      }
    } catch (e) {
      // Verificar si es un error de autenticación usando un mejor enfoque
      if (e is DioError && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (mounted) {
          _redirectToLogin();
        }
      } else {
        // Manejar otros errores normalmente
        if (mounted) {
          setState(() {
            _articlesError = e.toString();
            _isLoadingArticles = false;
          });
        }
      }
      print('Error cargando artículos: $e');
    }
  }
  
  // Método para redirigir al login cuando el token ha expirado
  void _redirectToLogin() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Cerrar sesión para limpiar datos y tokens
      await authProvider.logout();
      
      // Usar el navigatorKey global para navegación
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
      
      // Mostrar mensaje al usuario usando el contexto del navigatorKey
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('La sesión ha expirado. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error al redireccionar al login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artículos en Stock', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
        ),
        actions: [
          if (userData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadArticulos(userData.codCiudad),
              tooltip: 'Actualizar listado',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar artículos...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade100,
              Colors.white,
            ],
          ),
        ),
        child: _buildBody(context, authProvider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
    // Si se está cargando datos de usuario, mostrar indicador
    if (authProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Si hay un error con los datos de usuario, mostrar mensaje
    if (authProvider.error != null) {
      return _buildErrorWidget(
        'Error: ${authProvider.error}',
        () {
          Provider.of<AuthProvider>(context, listen: false).loadUserData();
        }
      );
    }
    
    // Si no hay datos de usuario, mostrar mensaje
    if (authProvider.userData == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos del usuario'),
      );
    }
    
    final userData = authProvider.userData!;
    
    // Si no hemos comenzado a cargar artículos todavía, cargarlos ahora
    if (_articulos.isEmpty && !_isLoadingArticles && _articlesError == null) {
      _loadArticulos(userData.codCiudad);
    }
    
    // Si se están cargando artículos, mostrar indicador
    if (_isLoadingArticles) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Si hay un error al cargar artículos, mostrar mensaje
    if (_articlesError != null) {
      return _buildErrorWidget(
        'Error al cargar artículos: $_articlesError',
        () => _loadArticulos(userData.codCiudad)
      );
    }
    
    // Si no hay artículos, mostrar mensaje
    if (_articulos.isEmpty) {
      return const Center(
        child: Text('No hay artículos disponibles para esta ciudad'),
      );
    }
    
    // Mostrar artículos
    return _buildArticulosList();
  }
  
  // Widget para mostrar mensajes de error con scroll
  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message, 
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildArticulosList() {
    // Agrupar artículos por codArticulo y datoArt
    Map<String, List<ArticuloPropuesto>> groupedArticulos = {};
    
    for (var articulo in _articulos) {
      final String datoArt = articulo.datoArt ?? "sin_dato";
      String key = '${articulo.codArticulo}_$datoArt';
      if (!groupedArticulos.containsKey(key)) {
        groupedArticulos[key] = [];
      }
      groupedArticulos[key]!.add(articulo);
    }

    // Filtrar por búsqueda si hay consulta
    List<String> filteredKeys = groupedArticulos.keys.where((key) {
      var items = groupedArticulos[key]!;
      return items.any((item) => 
        (item.datoArt ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (item.codArticulo?.toString() ?? '').contains(_searchQuery.toLowerCase()));
    }).toList();

    if (filteredKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron artículos',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: filteredKeys.length,
      itemBuilder: (context, index) {
        String key = filteredKeys[index];
        List<ArticuloPropuesto> articulosList = groupedArticulos[key]!;
        ArticuloPropuesto firstArticulo = articulosList.first;
        
        // Generar un color consistente basado en el código
        final int colorValue = firstArticulo.codArticulo?.hashCode ?? 0;
        final Color cardColor = Color((math.Random(colorValue).nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.2);
        
        // Agrupar por DB y Ciudad para mostrar precios organizados
        Map<String, Map<int, List<ArticuloPropuesto>>> dbCiudadPrecios = {};
        
        for (var art in articulosList) {
          final String db = art.db ?? "Sin DB";
          final int ciudad = art.codCiudad ?? 0;
          
          if (!dbCiudadPrecios.containsKey(db)) {
            dbCiudadPrecios[db] = {};
          }
          
          if (!dbCiudadPrecios[db]!.containsKey(ciudad)) {
            dbCiudadPrecios[db]![ciudad] = [];
          }
          
          dbCiudadPrecios[db]![ciudad]!.add(art);
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: cardColor,
              child: Text(
                firstArticulo.codArticulo?.toString().substring(0, 1) ?? "?",
                style: TextStyle(
                  color: cardColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        firstArticulo.datoArt ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copiar descripción',
                      onPressed: () {
                        _copyToClipboard(
                          context,
                          firstArticulo.datoArt ?? '',
                          'Descripción copiada'
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, 
                        size: 14, // Reducido de 16 a 14
                        color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Flexible( // Añadido Flexible aquí
                        child: SelectableText(
                          '${firstArticulo.codArticulo}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Reducido el tamaño de fuente
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          _copyToClipboard(
                            context,
                            firstArticulo.codArticulo?.toString() ?? '',
                            'Código copiado'
                          );
                        },
                        child: const Icon(Icons.content_copy, size: 12), // Reducido de 14 a 12
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                // Reemplazar el código anterior del subtítulo con este para solo mostrar el indicador de disponibilidad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: firstArticulo.disponible != null && firstArticulo.disponible! > 0
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    firstArticulo.disponible != null && firstArticulo.disponible! > 0
                        ? 'Disponible'
                        : 'Sin stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: firstArticulo.disponible != null && firstArticulo.disponible! > 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detalles del producto
                    _buildProductDetails(firstArticulo),
                    const Divider(thickness: 1),
                    
                    // Lista de precios por DB y Ciudad
                    ...dbCiudadPrecios.entries.map((dbEntry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: dbEntry.key == "ESP" 
                                ? Colors.blue.shade100 
                                : Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Base de datos: ${dbEntry.key}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dbEntry.key == "ESP" 
                                  ? Colors.blue.shade800 
                                  : Colors.purple.shade800,
                            ),
                          ),
                        ),
                        ...dbEntry.value.entries.map((ciudadEntry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.location_city, 
                                    size: 16, 
                                    color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ciudad: ${ciudadEntry.key}', 
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            ...ciudadEntry.value.map((art) => Container(
                              margin: const EdgeInsets.only(bottom: 8, left: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('Lista: ${art.listaPrecio ?? "N/A"}'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            art.condicionPrecio ?? 'Sin condición',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$${art.precio?.toStringAsFixed(2) ?? "0.00"}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        )).toList(),
                      ],
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Método para copiar al portapapeles
  void _copyToClipboard(BuildContext context, String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(successMessage),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 20,
            right: 20,
          ),
        ),
      );
    });
  }
  
  Widget _buildProductDetails(ArticuloPropuesto articulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory, size: 18),
            const SizedBox(width: 8),
            Text(
              'Disponible: ${articulo.disponible ?? 0}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Información técnica del producto
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (articulo.gramaje != null && articulo.gramaje != 0.0)
              _buildInfoChip('Gramaje: ${articulo.gramaje}', Colors.teal.shade100),
              
            if (articulo.unidadMedida != null)
              _buildInfoChip('Unidad: ${articulo.unidadMedida}', Colors.green.shade100),
              
            if (articulo.utm != null)
              _buildInfoChip('UTM: ${articulo.utm}', Colors.blue.shade100),
              
            _buildInfoChip('Familia: ${articulo.codigoFamilia ?? "N/A"}', Colors.amber.shade100),
              
            _buildInfoChip('Grupo SAP: ${articulo.codGrpFamiliaSap ?? "N/A"}', Colors.orange.shade100),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}