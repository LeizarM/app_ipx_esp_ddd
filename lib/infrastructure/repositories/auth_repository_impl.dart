

import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/core/utils/token_utils.dart';
import 'package:app_ipx_esp_ddd/domain/models/Login.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    await secureStorage.delete(key: 'token');  
    await secureStorage.delete(key: 'bearer');  
  }  
    
  @override  
  Future<String?> getToken() async {  
    return await secureStorage.read(key: 'token');  
  }  
    
  @override  
  Future<bool> refreshTokenIfNeeded() async {  
    // En un caso real, aquí implementarías la lógica para refrescar el token  
    // Por ahora, solo verificamos si está expirado  
    final token = await secureStorage.read(key: 'token');  
    if (token == null) return false;  
      
    if (TokenUtils.isTokenExpired(token)) {  
      // Token expirado, deberíamos refrescarlo  
      // Como no tenemos endpoint de refresh, simplemente cerramos sesión  
      await logout();  
      return false;  
    }  
      
    return true;  
  }  
}