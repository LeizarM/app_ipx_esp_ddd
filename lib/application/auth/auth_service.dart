import 'package:app_ipx_esp_ddd/domain/models/Login.dart';
import 'package:app_ipx_esp_ddd/domain/repositories/auth_repository.dart';

class AuthService {  
  final AuthRepository authRepository;  
    
  AuthService({required this.authRepository});  
    
  Future<Login> login(String username, String password) {  
    return authRepository.login(username, password);  
  }  
    
  Future<bool> isLoggedIn() {  
    return authRepository.isLoggedIn();  
  }  
    
  Future<void> logout() {  
    return authRepository.logout();  
  }  
    
  Future<bool> checkTokenValidity() {  
    return authRepository.refreshTokenIfNeeded();  
  }  

  Future<void> clearAuthData() async {
    try {
      // Limpiar los datos de autenticación del repository
      await authRepository.logout();
      
      // También puedes limpiar cualquier caché o estado adicional aquí
    } catch (e) {
      throw Exception('Error al limpiar datos de autenticación: $e');
    }
  }

  Future<Login?> getUserData() {
  return authRepository.getUserData();
}
}