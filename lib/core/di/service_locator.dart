import 'package:app_ipx_esp_ddd/application/articulo_propuesto/articulo_propuesto_service.dart';
import 'package:app_ipx_esp_ddd/core/network/dio_client.dart';
import 'package:app_ipx_esp_ddd/infrastructure/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../application/auth/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

// Navegador global para acceder desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GetIt getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  
  // NetworkClient
  getIt.registerLazySingleton(() => DioClient(
    secureStorage: getIt(),
    navigatorKey: navigatorKey,
  ));
  
  // Dio
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: getIt(), secureStorage: getIt()),
  );
  
  // Services
  getIt.registerLazySingleton(
    () => AuthService(authRepository: getIt()),
  );
  
  // Registrar el servicio de artículos
  getIt.registerLazySingleton<ArticuloService>(
    () => ArticuloService(
      dio: getIt(), 
      authRepository: getIt(),
    ),
  );
}