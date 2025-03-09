import 'package:app_ipx_esp_ddd/domain/models/ArticuloPropuesto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'dart:io';

class ArticuloDatabase {
  // Singleton instance
  static final ArticuloDatabase _singleton = ArticuloDatabase._();
  static ArticuloDatabase get instance => _singleton;
  
  // Private constructor
  ArticuloDatabase._();
  
  // Database instance
  Database? _db;
  
  // Store for articles - usando stringMapStoreFactory
  final StoreRef<String, Map<String, dynamic>> _articulosStore = 
      stringMapStoreFactory.store('articulos');
  
  // Store for metadata
  final StoreRef<String, dynamic> _metadataStore = 
      StoreRef<String, dynamic>('metadata');
  
  // Get database instance
  Future<Database> get database async {
    if (_db != null) return _db!;
    
    debugPrint('DB: Inicializando base de datos Sembast');
    _db = await _initDB('articulos_simple.db');
    return _db!;
  }
  
  // Open database based on platform
  Future<Database> _initDB(String dbName) async {
    try {
      if (kIsWeb) {
        final factory = databaseFactoryWeb;
        debugPrint('DB: Inicializando base de datos web');
        return await factory.openDatabase(dbName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final dbPath = join(appDir.path, dbName);
        debugPrint('DB: Ruta de la base de datos: $dbPath');
        return await databaseFactoryIo.openDatabase(dbPath);
      }
    } catch (e) {
      debugPrint('DB: Error al abrir la base de datos: $e');
      rethrow;
    }
  }
  
  // Método SIMPLIFICADO para guardar artículos
  Future<void> saveArticulos(List<ArticuloPropuesto> articulos, int codCiudad) async {
    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('DB: Guardando ${articulos.length} artículos para ciudad $codCiudad');
      final db = await database;
      
      // Primero, eliminar todos los artículos existentes para esta ciudad
      // Usando filter directamente
      final finder = Finder(
        filter: Filter.equals('codCiudad', codCiudad),
      );
      
      await _articulosStore.delete(db, finder: finder);
      debugPrint('DB: Artículos anteriores para ciudad $codCiudad eliminados');
      
      // Luego, insertar todos los nuevos artículos
      final List<String> keys = [];
      final List<Map<String, dynamic>> values = [];
      
      for (var articulo in articulos) {
        // Generar clave única SIMPLIFICADA (sin incluir la ciudad en la clave)
        final codArticulo = articulo.codArticulo?.toString() ?? '';
        final listaPrecio = articulo.listaPrecio?.toString() ?? '';
        final dbArticulo = articulo.db?.toString() ?? '';
        
        final key = '${codArticulo}_${listaPrecio}_${dbArticulo}_${DateTime.now().millisecondsSinceEpoch}';
        keys.add(key);
        
        // Convertir a Map y asegurar que codCiudad está correctamente guardado
        final Map<String, dynamic> articuloJson = articulo.toJson();
        // Asegurarnos de que codCiudad sea explícitamente guardado como entero
        articuloJson['codCiudad'] = codCiudad;
        
        values.add(articuloJson);
      }
      
      // Guardar todos los artículos en un solo paso
      await _articulosStore.records(keys).put(db, values);
      
      // Actualizar timestamp
      await _metadataStore.record('lastUpdate_$codCiudad').put(
        db, 
        DateTime.now().millisecondsSinceEpoch
      );
      
      stopwatch.stop();
      debugPrint('DB: Operación completada en ${stopwatch.elapsedMilliseconds}ms - Guardados: ${articulos.length}');
      
      // Verificar cuántos artículos se guardaron realmente
      // Usar findKey y contar manualmente
      final snapshots = await _articulosStore.find(
        db,
        finder: Finder(filter: Filter.equals('codCiudad', codCiudad))
      );
      debugPrint('DB: Artículos guardados en la base de datos para ciudad $codCiudad: ${snapshots.length}');
      
    } catch (e) {
      debugPrint('DB: Error al guardar artículos: $e');
      rethrow;
    }
  }
  
  // Método SIMPLIFICADO para obtener artículos
  Future<List<ArticuloPropuesto>> getArticulos(int codCiudad) async {
    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('DB: Obteniendo artículos para ciudad $codCiudad');
      
      final db = await database;
      
      // Filtro directo y simple por codCiudad
      final finder = Finder(
        filter: Filter.equals('codCiudad', codCiudad),
      );
      
      // Contar artículos primero para debug
      final snapshots = await _articulosStore.find(db, finder: finder);
      debugPrint('DB: Existen ${snapshots.length} artículos para ciudad $codCiudad');
      
      // Convertir a lista de ArticuloPropuesto
      final articulos = snapshots.map((snapshot) {
        return ArticuloPropuesto.fromJson(snapshot.value);
      }).toList();
      
      stopwatch.stop();
      debugPrint('DB: Recuperados ${articulos.length} artículos en ${stopwatch.elapsedMilliseconds}ms');
      return articulos;
      
    } catch (e) {
      debugPrint('DB: Error al obtener artículos: $e');
      return []; // Retornar lista vacía en caso de error para evitar bloqueos
    }
  }
  
  // Método simplificado para verificar si hay artículos
  Future<bool> hasArticulos(int codCiudad) async {
    try {
      final db = await database;
      
      // Primero buscar al menos un artículo
      final finder = Finder(
        filter: Filter.equals('codCiudad', codCiudad),
      );
      
      // Verificar si hay al menos un artículo
      final snapshot = await _articulosStore.findFirst(db, finder: finder);
      final hasData = snapshot != null;
      
      debugPrint('DB: ¿Ciudad $codCiudad tiene artículos? $hasData');
      return hasData;
      
    } catch (e) {
      debugPrint('DB: Error al verificar artículos: $e');
      return false;
    }
  }
  
  // Método simplificado para buscar artículos
  Future<List<ArticuloPropuesto>> searchArticulos(int codCiudad, {String? query}) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Si no hay consulta, devolver todos los artículos
      if (query == null || query.isEmpty) {
        return getArticulos(codCiudad);
      }
      
      debugPrint('DB: Buscando artículos para ciudad $codCiudad con query: "$query"');
      
      final db = await database;
      
      // Obtener todos los artículos de la ciudad
      final finder = Finder(
        filter: Filter.equals('codCiudad', codCiudad),
      );
      
      final snapshots = await _articulosStore.find(db, finder: finder);
      
      // Filtrar en memoria por consulta de búsqueda
      final queryLower = query.toLowerCase();
      final articulos = snapshots
          .where((snapshot) {
            final art = snapshot.value;
            final codArticulo = art['codArticulo']?.toString() ?? '';
            final datoArt = art['datoArt']?.toString() ?? '';
            
            return codArticulo.toLowerCase().contains(queryLower) || 
                  datoArt.toLowerCase().contains(queryLower);
          })
          .map((snapshot) => ArticuloPropuesto.fromJson(snapshot.value))
          .toList();
      
      stopwatch.stop();
      debugPrint('DB: Encontrados ${articulos.length} artículos en búsqueda (${stopwatch.elapsedMilliseconds}ms)');
      return articulos;
      
    } catch (e) {
      debugPrint('DB: Error al buscar artículos: $e');
      return [];
    }
  }
  
  // Obtener timestamp de última actualización
  Future<DateTime?> getLastUpdateTime(int codCiudad) async {
    try {
      final db = await database;
      final timestamp = await _metadataStore.record('lastUpdate_$codCiudad').get(db);
      
      if (timestamp == null) {
        debugPrint('DB: No hay timestamp para ciudad $codCiudad');
        return null;
      }
      
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      debugPrint('DB: Último timestamp para ciudad $codCiudad: ${dateTime.toString()}');
      return dateTime;
      
    } catch (e) {
      debugPrint('DB: Error al obtener timestamp: $e');
      return null;
    }
  }
  
  // Limpiar base de datos
  Future<void> clearDatabase() async {
    try {
      debugPrint('DB: Limpiando base de datos...');
      
      // Cerrar conexión actual
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
      
      // Eliminar archivo de base de datos
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final dbPath = join(appDir.path, 'articulos_simple.db');
        final dbFile = File(dbPath);
        
        if (await dbFile.exists()) {
          await dbFile.delete();
          debugPrint('DB: Archivo de base de datos eliminado');
        }
      } else {
        final factory = databaseFactoryWeb;
        await factory.deleteDatabase('articulos_simple.db');
        debugPrint('DB: Base de datos web eliminada');
      }
      
    } catch (e) {
      debugPrint('DB: Error al limpiar la base de datos: $e');
    }
  }
  
  // Depuración - listar todos los registros
  Future<void> countAllRecords() async {
    try {
      final db = await database;
      final snapshots = await _articulosStore.find(db);
      debugPrint('DB: Total de registros en la base de datos: ${snapshots.length}');
      
      // Listar los primeros 5 registros para depuración
      final samples = snapshots.take(5).toList();
      debugPrint('DB: Muestra de registros:');
      for (var snapshot in samples) {
        final ciudad = snapshot.value['codCiudad'];
        final articulo = snapshot.value['codArticulo'];
        final datoArt = snapshot.value['datoArt'];
        debugPrint('DB: - $articulo ($datoArt) - Ciudad: $ciudad');
      }
    } catch (e) {
      debugPrint('DB: Error al contar registros: $e');
    }
  }
}