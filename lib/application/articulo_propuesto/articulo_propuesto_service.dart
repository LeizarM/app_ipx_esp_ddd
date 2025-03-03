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
  
  Future<List<ArtciuloPropuesto>> getArticulos({
    String? search,
    int? codigoFamilia,
    String? moneda,
    int? disponible,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      // Construir parámetros de búsqueda
      Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (codigoFamilia != null) {
        queryParams['codigoFamilia'] = codigoFamilia;
      }
      
      if (moneda != null && moneda.isNotEmpty) {
        queryParams['moneda'] = moneda;
      }
      
      if (disponible != null) {
        queryParams['disponible'] = disponible;
      }
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}/pagina',
        queryParameters: queryParams,
      );
      
      return artciuloPropuestoFromJson(jsonEncode(response.data));
    } catch (e) {
      throw Exception('Error al obtener los artículos: ${e.toString()}');
    }
  }
  
  Future<List<int>> getFamilias() async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}/articulos/familias',
      );
      
      return List<int>.from(response.data);
    } catch (e) {
      throw Exception('Error al obtener las familias: ${e.toString()}');
    }
  }
  
  Future<List<String>> getMonedas() async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}/articulos/monedas',
      );
      
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Error al obtener las monedas: ${e.toString()}');
    }
  }
  
  Future<ArtciuloPropuesto> getArticuloDetalle(String codArticulo) async {
    try {
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}/articulos/$codArticulo',
      );
      
      return ArtciuloPropuesto.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener el detalle del artículo: ${e.toString()}');
    }
  }
}