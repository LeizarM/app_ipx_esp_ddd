import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/core/utils/token_utils.dart';
import 'package:app_ipx_esp_ddd/presentation/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class DioClient {  
  final FlutterSecureStorage secureStorage;
  final GlobalKey<NavigatorState> navigatorKey;
  late Dio dio;  
    
  DioClient({
    required this.secureStorage,
    required this.navigatorKey,  
  }) {  
    dio = Dio(  
      BaseOptions(  
        baseUrl: ApiConstants.baseUrl,  
        connectTimeout: const Duration(seconds: 15),  
        receiveTimeout: const Duration(seconds: 15),  
      ),  
    );  
      
    dio.interceptors.add(_authInterceptor());  
  }  
    
  Interceptor _authInterceptor() {  
    return InterceptorsWrapper(  
      onRequest: (options, handler) async {  
        // Obtener token  
        final token = await secureStorage.read(key: 'token');  
        final bearer = await secureStorage.read(key: 'bearer');  
          
        if (token != null && bearer != null) {  
          // Verificar si el token está expirado  
          if (TokenUtils.isTokenExpired(token)) {  
            // Token expirado, redirigir al login
            _redirectToLogin();
            
            // Completar la petición con error de autenticación
            final error = DioException(
              requestOptions: options,
              response: Response(
                statusCode: 401,
                requestOptions: options,
                statusMessage: 'Token expirado',
              ),
              type: DioExceptionType.badResponse,
              message: 'Token expirado',
            );
            
            handler.reject(error);
            return;
          }  
            
          // Agregar token a la solicitud  
          options.headers['Authorization'] = '$bearer $token';  
        }  
          
        handler.next(options);  
      },  
      onError: (DioException error, handler) async {  
        // Manejar errores de autenticación (401)  
        if (error.response?.statusCode == 401) {  
          // Token inválido o expirado, limpiar storage
          await secureStorage.delete(key: 'token');  
          await secureStorage.delete(key: 'bearer');
          await secureStorage.delete(key: 'user');  
          
          // Redirigir al login  
          _redirectToLogin();
        }  
          
        handler.next(error);  
      },  
    );  
  }
  
  /// Redirige al login usando el navigatorKey global
  void _redirectToLogin() {
    // Usamos un Future.microtask para evitar problemas con la ejecución en el mismo frame
    Future.microtask(() {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Primero cerrar sesión correctamente con el provider
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.logout().then((_) {
            // Navegar al login después de cerrar sesión
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          });
        } catch (e) {
          print('Error al cerrar sesión: $e');
          // Si falla el logout con el provider, intentar navegar de todos modos
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      }
    });
  }
}