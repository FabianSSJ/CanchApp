import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CompanyService {
  static Future<Map<String, dynamic>> createCompany({
    required String token,
    required int ownerId,
    required String companyName,
    required int companyCityId,
    required String companyPhone,
    required String companyEmail,
    required String companyLocation,
    required String companyDescription,
    required String companyServices,
    File? companyLogo,
  }) async {
    try {
      // 1. Subir la imagen primero si existe
      String? logoUrl;
      if (companyLogo != null) {
        logoUrl = await _uploadImage(companyLogo, token);
      }

      // 2. Crear el cuerpo de la solicitud
      final Map<String, dynamic> requestBody = {
        "company_name": companyName,
        "company_city_id": companyCityId,
        "company_phone": companyPhone,
        "company_email": companyEmail,
        "company_location": companyLocation,
        "company_description": companyDescription,
        "company_services": companyServices,
        "company_logo": logoUrl ?? "ruta/por/defecto/logo.png",
      };

      // 3. Enviar la solicitud
      final response = await http.post(
        Uri.parse('http://104.248.75.98:3000/companies/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // 4. Procesar la respuesta
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'companyId': responseData['id'],
          'companyData': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<String> _uploadImage(File imageFile, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://104.248.75.98:3000/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['imageUrl'];
      } else {
        throw Exception('Error al subir imagen: $responseData');
      }
    } catch (e) {
      throw Exception('Error en subida de imagen: $e');
    }
  }

  // Método para asociar la empresa al usuario
  static Future<void> associateCompanyToUser(
      String token, int userId, int companyId) async {
    try {
      final response = await http.post(
        Uri.parse('http://104.248.75.98:3000/users/associate-company'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'company_id': companyId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error asociando empresa: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en asociación: $e');
    }
  }
}