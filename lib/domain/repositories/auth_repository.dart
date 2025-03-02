import 'package:app_ipx_esp_ddd/domain/models/Login.dart';

abstract class AuthRepository {  
  Future<Login> login(String username, String password);  
  Future<bool> isLoggedIn();  
  Future<void> logout();  
  Future<String?> getToken();  
  Future<bool> refreshTokenIfNeeded();  
}