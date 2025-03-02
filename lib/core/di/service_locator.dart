import 'package:dio/dio.dart';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';  
import 'package:get_it/get_it.dart';  
import '../../domain/repositories/auth_repository.dart';  
import '../../infrastructure/repositories/auth_repository_impl.dart';  
import '../network/dio_client.dart';  
  
final getIt = GetIt.instance;  
  
void setupDependencies() {  
  // Servicios externos  
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());  
    
  // Configuración de red  
  getIt.registerLazySingleton<DioClient>(() => DioClient(secureStorage: getIt()));  
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);  
    
  // Repositorios  
  getIt.registerLazySingleton<AuthRepository>(  
    () => AuthRepositoryImpl(  
      dio: getIt(),  
      secureStorage: getIt(),  
    ),  
  );  
}