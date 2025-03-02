import 'package:flutter/material.dart';  
import '../../application/auth/auth_service.dart';  
import '../../core/di/service_locator.dart';  
import '../../domain/models/login.dart';  
  
class AuthProvider extends ChangeNotifier {  
  final AuthService _authService = AuthService(authRepository: getIt());  
    
  bool _isLoading = false;  
  bool _isAuthenticated = false;  
  Login? _userData;  
  String? _error;  
    
  bool get isLoading => _isLoading;  
  bool get isAuthenticated => _isAuthenticated;  
  Login? get userData => _userData;  
  String? get error => _error;  
    
  AuthProvider() {  
    checkAuthStatus();  
  }  
    
  Future<void> checkAuthStatus() async {  
    _isLoading = true;  
    notifyListeners();  
      
    try {  
      _isAuthenticated = await _authService.isLoggedIn();  
    } catch (e) {  
      _isAuthenticated = false;  
    }  
      
    _isLoading = false;  
    notifyListeners();  
  }  
    
  Future<bool> login(String username, String password) async {  
    _isLoading = true;  
    _error = null;  
    notifyListeners();  
      
    try {  
      final _userData = await _authService.login(username, password);
      _isAuthenticated = true;  
      _isLoading = false;  
      notifyListeners();  
      return true;  
    } catch (e) {  
      _error = e.toString();  
      _isAuthenticated = false;  
      _isLoading = false;  
      notifyListeners();  
      return false;  
    }  
  }  
    
  Future<void> logout() async {  
    _isLoading = true;  
    notifyListeners();  
      
    await _authService.logout();  
    _isAuthenticated = false;  
    _userData = null;  
      
    _isLoading = false;  
    notifyListeners();  
  }  
}