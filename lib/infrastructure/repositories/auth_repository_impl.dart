import 'dart:convert';
import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/core/utils/token_utils.dart';
import 'package:app_ipx_esp_ddd/domain/models/Login.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {  
  final Dio dio;  
  final FlutterSecureStorage secureStorage;  
    
  AuthRepositoryImpl({required this.dio, required this.secureStorage});  
    
  @override  
  Future<Login> login(String username, String password) async {  
    try {  
      final response = await dio.post(  
        '${ApiConstants.loginEndpoint}/login',  
        data: {  
          'login': username,  
          'password2': password,  
        },  
      );  
        
      final login = Login.fromJson(response.data);  
        
      // Guardar token  
      await secureStorage.write(key: 'token', value: login.token);  
      await secureStorage.write(key: 'bearer', value: login.bearer);
      await secureStorage.write(key: 'user', value: jsonEncode(login));    
        
      return login;  
    } catch (e) {  
      throw Exception('Error al iniciar sesión: ${e.toString()}');  
    }  
  }  
    
  @override  
  Future<bool> isLoggedIn() async {  
    final token = await secureStorage.read(key: 'token');  
    if (token == null) return false;  
      
    return !TokenUtils.isTokenExpired(token);  
  }  
    
  @override  
  Future<void> logout() async {  
    try {
      // Opcional: Intentar hacer logout en el servidor si tu API lo soporta
      final token = await secureStorage.read(key: 'token');
      final bearer = await secureStorage.read(key: 'bearer');
      
      if (token != null && bearer != null) {
        try {
          await dio.post(
            '${ApiConstants.loginEndpoint}/logout',
            options: Options(
              headers: {'Authorization': '$bearer $token'},
            ),
          );
        } catch (e) {
          // Ignorar errores al notificar logout
          if (kDebugMode) {
            print('Error al notificar logout al servidor: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error durante el intento de logout en servidor: $e');
      }
    } finally {
      // Siempre limpiar el almacenamiento local
      await secureStorage.delete(key: 'token');  
      await secureStorage.delete(key: 'bearer');  
      await secureStorage.delete(key: 'user');
    }
  }  
    
  @override  
  Future<String?> getToken() async {  
    return await secureStorage.read(key: 'token');  
  }  
    
  @override  
  Future<bool> refreshTokenIfNeeded() async {  
    // Obtener token actual
    final token = await secureStorage.read(key: 'token');  
    if (token == null) return false;  
    
    // Si el token ya está expirado, no hay más que hacer
    if (TokenUtils.isTokenExpired(token)) {
      return false;
    }
      
    // Si el token está a punto de expirar (menos de 10 minutos)
    if (TokenUtils.isTokenNearExpiration(token, minutesThreshold: 10)) {
      try {
        // Intentar refrescar el token - Adapta esto según tu API
        final bearer = await secureStorage.read(key: 'bearer');
        if (bearer == null) return false;
        
        // Ejemplo de refreshToken - Ajusta según tu API real
        try {
          final response = await dio.post(  
            '${ApiConstants.loginEndpoint}/refresh-token',  
            options: Options(
              headers: {
                'Authorization': '$bearer $token'
              }
            ),
          );
          
          // Si la respuesta es exitosa y tenemos un nuevo token
          if (response.statusCode == 200 && response.data['token'] != null) {
            // Guardar el nuevo token
            await secureStorage.write(key: 'token', value: response.data['token']);
            
            // Actualizar el objeto de usuario
            final userStr = await secureStorage.read(key: 'user');
            if (userStr != null) {
              final userData = jsonDecode(userStr);
              userData['token'] = response.data['token'];
              await secureStorage.write(key: 'user', value: jsonEncode(userData));
            }
            
            return true;
          }
        } catch (e) {
          // Ignorar errores de refresh y verificar si el token original sigue válido
          if (kDebugMode) {
            print('Error al refrescar token: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error general en refreshTokenIfNeeded: $e');
        }
      }
    }
    
    // Si llegamos aquí, verificar si el token original sigue siendo válido
    return !TokenUtils.isTokenExpired(token);
  }
  
  @override
  Future<Login> getUserData() async {
    try {
      final userData = await secureStorage.read(key: 'user');
      if (userData == null) {
        throw Exception('No se encontraron datos del usuario');
      }
      
      return Login.fromJson(jsonDecode(userData));
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: ${e.toString()}');
    }
  }  
}