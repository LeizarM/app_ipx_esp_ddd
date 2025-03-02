import 'package:jwt_decoder/jwt_decoder.dart';

class TokenUtils {  
  static bool isTokenExpired(String token) {  
    try {  
      return JwtDecoder.isExpired(token);  
    } catch (e) {  
      return true;  
    }  
  }  
    
  static Map<String, dynamic> decodeToken(String token) {  
    try {  
      return JwtDecoder.decode(token);  
    } catch (e) {  
      return {};  
    }  
  }  
}