import 'package:jwt_decoder/jwt_decoder.dart';

class TokenUtils {  
  /// Verifica si un token está expirado
  static bool isTokenExpired(String token) {  
    try {  
      return JwtDecoder.isExpired(token);  
    } catch (e) {  
      print('Error verificando expiración de token: $e');
      return true; // En caso de error, asumir que está expirado
    }  
  }  
  
  /// Verifica si un token está cerca de expirar (por defecto: 5 minutos)
  static bool isTokenNearExpiration(String token, {int minutesThreshold = 5}) {  
    try {  
      // Obtener información del token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // Obtener tiempo de expiración
      final expTime = decodedToken['exp'];
      if (expTime == null) return true;
      
      // Convertir a DateTime
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(expTime * 1000);
      
      // Verificar si está dentro del umbral de tiempo
      final thresholdTime = DateTime.now().add(Duration(minutes: minutesThreshold));
      
      // Si el tiempo de umbral es después de la expiración, está por expirar
      return thresholdTime.isAfter(expirationTime);
    } catch (e) {  
      print('Error verificando proximidad de expiración: $e');
      return true; // En caso de error, asumir que está a punto de expirar
    }  
  }
    
  /// Decodifica un token
  static Map<String, dynamic> decodeToken(String token) {  
    try {  
      return JwtDecoder.decode(token);  
    } catch (e) {  
      print('Error decodificando token: $e');
      return {};  
    }  
  }
  
  /// Obtiene el tiempo restante en segundos del token
  static int getRemainingTime(String token) {
    try {
      // Obtener información del token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // Obtener tiempo de expiración
      final expTime = decodedToken['exp'];
      if (expTime == null) return 0;
      
      // Convertir a DateTime
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(expTime * 1000);
      final currentTime = DateTime.now();
      
      // Si ya expiró, retornar 0
      if (currentTime.isAfter(expirationTime)) {
        return 0;
      }
      
      // Calcular diferencia en segundos
      return expirationTime.difference(currentTime).inSeconds;
    } catch (e) {
      print('Error calculando tiempo restante: $e');
      return 0;
    }
  }
}