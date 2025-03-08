// lib/application/articulos/articulo_service.dart
import 'dart:convert';
import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/domain/models/ArticuloPropuesto.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

class ArticuloService {
  final Dio dio;
  final AuthRepository authRepository;
  
  ArticuloService({required this.dio, required this.authRepository});
  
  Future<List<ArtciuloPropuesto>> getArticulosxCity( int codCiudad ) async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      // Construir parámetros de búsqueda
      Map<String, dynamic> queryParams = {
        'codCiudad': codCiudad,
      };
      
      
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}/paginaXApp/articulosX',
        queryParameters: queryParams,
      );
      
      return artciuloPropuestoFromJson(jsonEncode(response.data));
    } catch (e) {
      throw Exception('Error al obtener los artículos: ${e.toString()}');
    }
  }
  
  
}