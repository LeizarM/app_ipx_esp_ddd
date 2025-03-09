import 'dart:convert';
import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/domain/models/ArticuloPropuesto.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:app_ipx_esp_ddd/infrastructure/database/articulo_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticuloService {
  final Dio dio;
  final AuthRepository authRepository;
  final ArticuloDatabase _db = ArticuloDatabase.instance;
  
  // Clave para SharedPreferences
  static const String _firstLoadKeyPrefix = 'first_load_articulos_v3_';
  static const String _lastUpdateKeyPrefix = 'last_update_articulos_v3_';
  
  // Flag para sincronización después de login
  bool _hasSyncedAfterLogin = false;
  
  // Flag para indicar si hay una sincronización en progreso
  bool _isSyncing = false;
  
  ArticuloService({required this.dio, required this.authRepository});
  
  // Método principal para obtener artículos
  Future<List<ArticuloPropuesto>> getArticulosxCity(int codCiudad, {bool forceRefresh = false}) async {
    try {
      debugPrint('ARTICULOS: Llamada a getArticulosxCity para ciudad $codCiudad (forceRefresh: $forceRefresh)');
      
      // Siempre forzar sincronización en desarrollo para depuración
      forceRefresh = true; // FORZAR PARA DEPURACIÓN
      
      // Verificar si hay datos locales antes de sincronizar
      final hasLocalDataBefore = await _db.hasArticulos(codCiudad);
      debugPrint('ARTICULOS: ¿Hay datos locales antes de sincronizar? $hasLocalDataBefore');
      
      // Sincronizar datos
      if (!_hasSyncedAfterLogin || forceRefresh) {
        debugPrint('ARTICULOS: Iniciando sincronización forzada');
        await _syncArticulos(codCiudad, forceRefresh: forceRefresh);
        _hasSyncedAfterLogin = true;
      }
      
      // Verificar si hay datos locales después de sincronizar
      final hasLocalDataAfter = await _db.hasArticulos(codCiudad);
      debugPrint('ARTICULOS: ¿Hay datos locales después de sincronizar? $hasLocalDataAfter');
      
      // Obtener los artículos de la base de datos local
      final articulos = await _db.getArticulos(codCiudad);
      debugPrint('ARTICULOS: Recuperados ${articulos.length} artículos de la base de datos local');
      
      return articulos;
    } catch (e) {
      debugPrint('ARTICULOS: Error al obtener artículos: $e');
      debugPrint('ARTICULOS: Tipo de error: ${e.runtimeType}');
      
      if (e is DioException) {
        debugPrint('ARTICULOS: Error de Dio tipo: ${e.type}');
        debugPrint('ARTICULOS: URL de solicitud: ${e.requestOptions.uri}');
        debugPrint('ARTICULOS: Código de respuesta: ${e.response?.statusCode}');
        debugPrint('ARTICULOS: Mensaje de respuesta: ${e.response?.statusMessage}');
        debugPrint('ARTICULOS: Datos de respuesta: ${e.response?.data}');
      }
      
      // Verificar si hay datos locales
      final hasLocalData = await _db.hasArticulos(codCiudad);
      if (hasLocalData) {
        debugPrint('ARTICULOS: Usando datos locales como respaldo');
        return await _db.getArticulos(codCiudad);
      }
      
      rethrow;
    }
  }
  
  // Método privado para sincronizar artículos con la API
  Future<void> _syncArticulos(int codCiudad, {bool forceRefresh = false}) async {
    // Evitar múltiples sincronizaciones simultáneas
    if (_isSyncing) {
      debugPrint('ARTICULOS: Ya hay una sincronización en progreso');
      return;
    }
    
    _isSyncing = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String firstLoadKey = _firstLoadKeyPrefix + codCiudad.toString();
      final String lastUpdateKey = _lastUpdateKeyPrefix + codCiudad.toString();
      
      // Verificar si es primera carga
      final bool isFirstLoad = !(prefs.getBool(firstLoadKey) ?? false);
      
      // Verificar tiempo desde última actualización
      final int lastUpdateTime = prefs.getInt(lastUpdateKey) ?? 0;
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      final bool needsUpdate = (currentTime - lastUpdateTime) > 24 * 60 * 60 * 1000; // 24 horas
      
      // Verificar si hay datos locales
      final hasLocalData = await _db.hasArticulos(codCiudad);
      
      debugPrint('ARTICULOS: Sincronización - isFirstLoad: $isFirstLoad, forceRefresh: $forceRefresh, needsUpdate: $needsUpdate, hasLocalData: $hasLocalData');
      
      // Solo sincronizar si es necesario (o forzamos por depuración)
      if (true || isFirstLoad || forceRefresh || needsUpdate || !hasLocalData) { // Siempre true para depuración
        debugPrint('ARTICULOS: Sincronizando artículos para ciudad $codCiudad');
        
        // Obtener token válido
        final token = await authRepository.getToken();
        if (token == null) {
          throw Exception('No se encontró un token válido');
        }
        debugPrint('ARTICULOS: Token obtenido para sincronización');
        
        // Configurar headers
        dio.options.headers["Authorization"] = "Bearer $token";
        
        // Crear body de la solicitud
        Map<String, dynamic> requestBody = {
          'codCiudad': codCiudad,
        };
        
        debugPrint('ARTICULOS: Enviando solicitud a ${ApiConstants.baseUrl}/paginaXApp/articulosX');
        debugPrint('ARTICULOS: Cuerpo de la solicitud: $requestBody');
        
        // Realizar la petición
        final response = await dio.post(
          '${ApiConstants.baseUrl}/paginaXApp/articulosX',
          data: requestBody,
          options: Options(
            sendTimeout: const Duration(seconds: 120),
            receiveTimeout: const Duration(seconds: 120),
          ),
        );
        
        debugPrint('ARTICULOS: Respuesta recibida, código ${response.statusCode}');
        
        if (response.data == null) {
          throw Exception('La API devolvió datos nulos');
        }
        
        // Verificar si la respuesta es una lista
        if (response.data is! List) {
          debugPrint('ARTICULOS: ADVERTENCIA: La respuesta no es una lista. Tipo: ${response.data.runtimeType}');
          debugPrint('ARTICULOS: Muestra de datos: ${response.data.toString().substring(0, min(200, response.data.toString().length))}...');
        } else {
          debugPrint('ARTICULOS: Recibidos ${(response.data as List).length} elementos de la API');
        }
        
        // Procesar datos
        final jsonString = jsonEncode(response.data);
        final articulos = await compute(_parseArticulos, jsonString);
        
        debugPrint('ARTICULOS: Procesados ${articulos.length} artículos del JSON');
        
        if (articulos.isEmpty) {
          debugPrint('ARTICULOS: ADVERTENCIA: La API devolvió una lista vacía de artículos');
        } else {
          // Tomar muestra del primer artículo para depuración
          final sampleArticulo = articulos.first.toJson();
          debugPrint('ARTICULOS: Muestra del primer artículo: ${sampleArticulo.toString().substring(0, min(200, sampleArticulo.toString().length))}...');
          
          // Guardar en la base de datos local
          debugPrint('ARTICULOS: Guardando ${articulos.length} artículos en la base de datos local');
          await _db.saveArticulos(articulos, codCiudad);
          
          // Verificar si los artículos se guardaron correctamente
          final savedCount = (await _db.getArticulos(codCiudad)).length;
          debugPrint('ARTICULOS: Se guardaron $savedCount artículos en la base de datos');
        }
        
        // Actualizar preferencias
        await prefs.setBool(firstLoadKey, true);
        await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
        
        debugPrint('ARTICULOS: Sincronización completada para ciudad $codCiudad');
      } else {
        debugPrint('ARTICULOS: No es necesario sincronizar para ciudad $codCiudad');
      }
    } catch (e) {
      debugPrint('ARTICULOS: Error al sincronizar artículos: $e');
      debugPrint('ARTICULOS: Tipo de error: ${e.runtimeType}');
      
      if (e is DioException) {
        debugPrint('ARTICULOS: Error de Dio tipo: ${e.type}');
        debugPrint('ARTICULOS: URL de solicitud: ${e.requestOptions.uri}');
        debugPrint('ARTICULOS: Código de respuesta: ${e.response?.statusCode}');
        debugPrint('ARTICULOS: Mensaje de respuesta: ${e.response?.statusMessage}');
        debugPrint('ARTICULOS: Datos de respuesta: ${e.response?.data}');
      }
      
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
  
  // Función estática para procesar datos en un isolate
  static List<ArticuloPropuesto> _parseArticulos(String jsonStr) {
    try {
      debugPrint('ARTICULOS: Parseando JSON (longitud: ${jsonStr.length})');
      final result = artciuloPropuestoFromJson(jsonStr);
      debugPrint('ARTICULOS: JSON parseado exitosamente, ${result.length} elementos');
      return result;
    } catch (e) {
      debugPrint('ARTICULOS: Error al analizar JSON: $e');
      debugPrint('ARTICULOS: Muestra del JSON: ${jsonStr.substring(0, min(200, jsonStr.length))}...');
      return [];
    }
  }
  
  // Función auxiliar para min
  static int min(int a, int b) {
    return a < b ? a : b;
  }
  
  // Obtener timestamp de última actualización
  Future<DateTime?> getLastUpdateTime(int codCiudad) async {
    return await _db.getLastUpdateTime(codCiudad);
  }
  
  // Resetear estado de sincronización
  void resetSyncState() {
    _hasSyncedAfterLogin = false;
  }
  
  // Método para forzar resincronización completa
  Future<void> resetAndSync(int codCiudad) async {
    try {
      debugPrint('ARTICULOS: Iniciando resetAndSync para ciudad $codCiudad');
      
      // Resetear preferencias
      final prefs = await SharedPreferences.getInstance();
      final String firstLoadKey = _firstLoadKeyPrefix + codCiudad.toString();
      final String lastUpdateKey = _lastUpdateKeyPrefix + codCiudad.toString();
      
      await prefs.remove(firstLoadKey);
      await prefs.remove(lastUpdateKey);
      
      // Resetear estado
      _hasSyncedAfterLogin = false;
      
      // Forzar sincronización
      await _syncArticulos(codCiudad, forceRefresh: true);
      
      debugPrint('ARTICULOS: Reset y resincronización completados para ciudad $codCiudad');
    } catch (e) {
      debugPrint('ARTICULOS: Error al resetear y resincronizar: $e');
      rethrow;
    }
  }
  
  // Método para limpiar completamente
  Future<void> resetCompletely() async {
    try {
      debugPrint('ARTICULOS: Iniciando resetCompletely');
      
      // Limpiar base de datos
      await _db.clearDatabase();
      
      // Limpiar preferencias
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_firstLoadKeyPrefix) || 
            key.startsWith(_lastUpdateKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      
      // Resetear estado
      _hasSyncedAfterLogin = false;
      _isSyncing = false;
      
      debugPrint('ARTICULOS: Reset completo del sistema de artículos');
    } catch (e) {
      debugPrint('ARTICULOS: Error al resetear completamente: $e');
      rethrow;
    }
  }
}