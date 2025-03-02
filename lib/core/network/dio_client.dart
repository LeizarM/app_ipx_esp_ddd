
import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/core/utils/token_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {  
  final FlutterSecureStorage secureStorage;  
  late Dio dio;  
    
  DioClient({required this.secureStorage}) {  
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
            // Token expirado, deberíamos manejar esto  
            // Por ahora, simplemente no enviamos el token  
            handler.next(options);  
            return;  
          }  
            
          // Agregar token a la solicitud  
          options.headers['Authorization'] = '$bearer $token';  
        }  
          
        handler.next(options);  
      },  
      onError: (DioException error, handler) {  
        // Manejar errores de autenticación (401)  
        if (error.response?.statusCode == 401) {  
          // Token inválido o expirado  
          secureStorage.delete(key: 'token');  
          secureStorage.delete(key: 'bearer');  
          // Aquí podrías redirigir al login  
        }  
          
        handler.next(error);  
      },  
    );  
  }  
}