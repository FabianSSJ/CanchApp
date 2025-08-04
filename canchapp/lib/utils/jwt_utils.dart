// utils/jwt_utils.dart
import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token inválido');
    
    final payload = _decodeBase64(parts[1]);
    return jsonDecode(payload);
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    
    switch (output.length % 4) {
      case 0: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
      default: throw Exception('Formato Base64 incorrecto');
    }
    
    return utf8.decode(base64Url.decode(output));
  }
}