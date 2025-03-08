import 'package:app_ipx_esp_ddd/core/constants/api_constants.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final Dio dio;
  final AuthRepository authRepository;
  
  UserService({required this.dio, required this.authRepository});
  
  // Get user's city code from local storage or API
  Future<int> getUserCityCode() async {
    try {
      // First check if we have it stored locally
      final prefs = await SharedPreferences.getInstance();
      final storedCodCiudad = prefs.getInt('user_city_code');
      
      if (storedCodCiudad != null) {
        return storedCodCiudad;
      }
      
      // If not stored locally, fetch from API
      final token = await authRepository.getToken();
      if (token == null) {
        throw Exception('No se encontró un token válido');
      }
      
      dio.options.headers["Authorization"] = "Bearer $token";
      
      final response = await dio.get('${ApiConstants.baseUrl}/usuario/perfil');
      
      if (response.statusCode == 200 && response.data != null) {
        final codCiudad = response.data['codCiudad'] as int;
        
        // Store for future use
        await prefs.setInt('user_city_code', codCiudad);
        
        return codCiudad;
      } else {
        throw Exception('No se pudo obtener el código de ciudad');
      }
    } catch (e) {
      // If there's an error, return a default city code (1 in this case)
      // You might want to handle this differently in a real app
      return 1;
    }
  }
}
