import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import 'package:app_ipx_esp_ddd/application/articulo_propuesto/articulo_propuesto_service.dart';
import 'package:app_ipx_esp_ddd/domain/models/ArticuloPropuesto.dart';
import 'package:app_ipx_esp_ddd/core/di/service_locator.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class ItemsViewStock extends StatefulWidget {
  const ItemsViewStock({super.key});

  @override
  State<ItemsViewStock> createState() => _ItemsViewStockState();
}

class _ItemsViewStockState extends State<ItemsViewStock> {
  bool _isLoadingArticles = false;
  List<ArticuloPropuesto> _articulos = [];
  List<ArticuloPropuesto> _displayedArticulos = []; // Artículos actualmente mostrados
  String? _articlesError;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _lastUpdateTime;
  bool _loadedFromCache = false;
  
  // Paginación
  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  // Claves para SharedPreferences
  static const String _firstLoadKey = 'first_load_items_view';
  
  @override
  void initState() {
    super.initState();
    
    // Configurar controlador de scroll
    _scrollController.addListener(_scrollListener);
    
    // Iniciar carga cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }
  
  // Detectar cuando el usuario llega al final de la lista
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Cuando estamos cerca del final, cargar más artículos
      _loadMoreItems();
    }
  }
  
  // Carga inicial
  Future<void> _initialLoad() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Cargar datos de usuario si es necesario
    if (authProvider.userData == null && !authProvider.isLoading) {
      await authProvider.loadUserData();
    }
    
    // Si tenemos usuario, cargar artículos
    if (authProvider.userData != null) {
      // Verificar si es la primera vez que se abre esta pantalla
      final prefs = await SharedPreferences.getInstance();
      final isFirstLoad = !(prefs.getBool(_firstLoadKey) ?? false);
      
      // Si es primera carga o no tenemos datos en caché, cargar de API
      await _loadArticulos(
        authProvider.userData!.codCiudad, 
        forceRefresh: isFirstLoad
      );
      
      // Marcar que ya no es primera carga
      if (isFirstLoad) {
        await prefs.setBool(_firstLoadKey, true);
      }
    }
  }
  
  // Cargar más artículos (para paginación)
  void _loadMoreItems() {
    if (_isLoadingMore || _displayedArticulos.length >= _articulos.length) {
      return;
    }
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Calcular cuántos artículos más cargar
    final int startIndex = _displayedArticulos.length;
    final int endIndex = math.min(startIndex + _pageSize, _articulos.length);
    
    // Simular un pequeño retraso para no bloquear la UI
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _displayedArticulos.addAll(_articulos.sublist(startIndex, endIndex));
          _isLoadingMore = false;
        });
      }
    });
  }
  
  // Cargar artículos usando el codCiudad del usuario
  Future<void> _loadArticulos(int codCiudad, {bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingArticles = true;
      _articlesError = null;
    });
    
    try {
      // Obtener el repositorio de autenticación
      final authRepository = getIt<AuthRepository>();
      
      // Verificar y refrescar el token si es necesario antes de la petición
      final isTokenValid = await authRepository.refreshTokenIfNeeded();

      if (!isTokenValid) {
        if (mounted) {
          _redirectToLogin();
        }
        return;
      }
      
      // Continuar con la petición de artículos
      final articuloService = Provider.of<ArticuloService>(context, listen: false);
      
      // Obtener la última fecha de actualización antes de cargar los artículos
      final lastUpdateBefore = await articuloService.getLastUpdateTime(codCiudad);
      
      // Cargar artículos (desde caché o API según forceRefresh)
      final articulos = await articuloService.getArticulosxCity(codCiudad, forceRefresh: forceRefresh);
      
      // Obtener la última fecha de actualización después de cargar artículos
      final lastUpdateAfter = await articuloService.getLastUpdateTime(codCiudad);
      
      // Determinar si se cargó desde caché o desde API
      final loadedFromCache = lastUpdateBefore != null && 
                             lastUpdateAfter != null && 
                             lastUpdateBefore.millisecondsSinceEpoch == lastUpdateAfter.millisecondsSinceEpoch;
      
      if (mounted) {
        setState(() {
          _articulos = articulos;
          // Inicializar con los primeros elementos para carga rápida
          _displayedArticulos = articulos.take(_pageSize).toList();
          _isLoadingArticles = false;
          _lastUpdateTime = lastUpdateAfter;
          _loadedFromCache = loadedFromCache;
        });
      }
    } catch (e) {
      // Verificar si es un error de autenticación
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
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
      debugPrint('Error cargando artículos: $e');
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
      
      // Mostrar mensaje al usuario
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
      debugPrint('Error al redireccionar al login: $e');
    }
  }

  // Aplicar filtro de búsqueda
  void _applySearchFilter(String query) {
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        // Si no hay búsqueda, mostrar solo los primeros elementos
        _displayedArticulos = _articulos.take(_pageSize).toList();
      } else {
        // Si hay búsqueda, filtrar todos los artículos
        final queryLower = query.toLowerCase();
        _displayedArticulos = _articulos.where((articulo) {
          final codArticulo = articulo.codArticulo?.toString() ?? '';
          final datoArt = articulo.datoArt?.toString() ?? '';
          return codArticulo.toLowerCase().contains(queryLower) || 
                 datoArt.toLowerCase().contains(queryLower);
        }).take(100).toList(); // Limitar resultados de búsqueda para mejor rendimiento
      }
    });
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
              onPressed: () => _loadArticulos(userData.codCiudad, forceRefresh: true),
              tooltip: 'Actualizar desde servidor',
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
                        _applySearchFilter('');
                      },
                    )
                  : null,
              ),
              onChanged: _applySearchFilter,
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
        child: Column(
          children: [
            if (_lastUpdateTime != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: _loadedFromCache ? Colors.amber.shade100 : Colors.green.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _loadedFromCache ? Icons.storage : Icons.cloud_done, 
                      size: 14, 
                      color: _loadedFromCache ? Colors.amber.shade800 : Colors.green.shade800
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _loadedFromCache
                          ? 'Datos desde caché local: ${_formatDateTime(_lastUpdateTime!)}'
                          : 'Actualizado: ${_formatDateTime(_lastUpdateTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _loadedFromCache ? Colors.amber.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  // Formatear fecha y hora para mostrar
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
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
    
    // Si se están cargando artículos inicialmente, mostrar indicador
    if (_isLoadingArticles && _articulos.isEmpty) {
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
    
    // Si no hay resultados para la búsqueda
    if (_displayedArticulos.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron artículos para "$_searchQuery"',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Mostrar artículos con paginación
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
    // Agrupar artículos por codArticulo y datoArt (solo para los que se muestran)
    Map<String, List<ArticuloPropuesto>> groupedArticulos = {};
    
    for (var articulo in _displayedArticulos) {
      final String datoArt = articulo.datoArt ?? "sin_dato";
      String key = '${articulo.codArticulo}_$datoArt';
      if (!groupedArticulos.containsKey(key)) {
        groupedArticulos[key] = [];
      }
      groupedArticulos[key]!.add(articulo);
    }

    // Convertir a lista ordenada para ListView
    final List<MapEntry<String, List<ArticuloPropuesto>>> groupedList = 
        groupedArticulos.entries.toList();
    
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(10.0),
          itemCount: groupedList.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Mostrar indicador de carga al final
            if (_isLoadingMore && index == groupedList.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final entry = groupedList[index];
            final List<ArticuloPropuesto> articulosList = entry.value;
            final ArticuloPropuesto firstArticulo = articulosList.first;
            
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
                            size: 14,
                            color: Theme.of(context).primaryColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: SelectableText(
                              '${firstArticulo.codArticulo}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
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
                            child: const Icon(Icons.content_copy, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
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
        ),
        
        // Recargar artículos mientras se desplaza hacia abajo
        if (_isLoadingArticles && _articulos.isNotEmpty)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
      ],
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
    _scrollController.dispose();
    super.dispose();
  }
}