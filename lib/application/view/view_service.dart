import 'dart:convert';
import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/domain/models/vista.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MenuService {
  final Dio dio;
  final AuthRepository authRepository;
  
  MenuService({required this.dio, required this.authRepository});
  
  Future<List<Vista>> getMenu(int codUsuario) async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      // Configurar Dio para esta petición
      dio.options.headers["Authorization"] = "Bearer $token";
      
      if (kDebugMode) {
        print('Obteniendo menú para el usuario: $codUsuario');
      }
      
      final response = await dio.post(
        '${ApiConstants.baseUrl}/view/vistaDinamica',
        data: {
          "codUsuario": codUsuario
        },
      );
      
      if (kDebugMode) {
        print('Respuesta status: ${response.statusCode}');
        print('Número de elementos raíz: ${response.data.length}');
      }
      
      // Validar la respuesta
      if (response.data == null) {
        throw Exception('La respuesta no contiene datos');
      }
      
      // Convertir a JSON string y luego parsear para garantizar que se siga la estructura correcta
      final jsonString = jsonEncode(response.data);
      
      if (kDebugMode) {
        print('Parseando respuesta a objetos Vista...');
      }
      
      final menuItems = vistaFromJson(jsonString);
      
      if (kDebugMode) {
        // Imprimir información de depuración sobre la estructura
        print('Número de elementos de menú principal: ${menuItems.length}');
        for (var item in menuItems) {
          print('- ${item.label} (${item.codVista}): ${item.items?.length ?? 0} subítems');
          _logChildItems(item.items, 1);
        }
      }
      
      return menuItems;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener el menú: $e');
      }
      throw Exception('Error al obtener el menú: ${e.toString()}');
    }
  }
  
  // Función recursiva para imprimir la estructura del menú (solo en debug)
  void _logChildItems(List<Vista>? items, int level) {
    if (items == null || items.isEmpty || !kDebugMode) return;
    
    String indent = ' ' * (level * 2);
    for (var item in items) {
      print('$indent- ${item.label} (${item.codVista}): ${item.items?.length ?? 0} subítems');
      _logChildItems(item.items, level + 1);
    }
  }
}