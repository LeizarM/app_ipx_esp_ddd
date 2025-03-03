import 'package:app_ipx_esp_ddd/application/view/view_service.dart';
import 'package:flutter/material.dart';
import 'package:app_ipx_esp_ddd/domain/models/vista.dart';

import 'package:app_ipx_esp_ddd/core/di/service_locator.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService(dio: getIt(), authRepository: getIt());
  
  bool _isLoading = false;
  List<Vista> _menuItems = [];
  String? _error;
  
  bool get isLoading => _isLoading;
  List<Vista> get menuItems => _menuItems;
  String? get error => _error;
  
  Future<void> loadMenu(int codUsuario) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _menuItems = await _menuService.getMenu(codUsuario);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}