import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FieldService {
  // URL base de tu API
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Tipos de cancha disponibles
  static List<String> getFieldTypes() {
    return [
      'Fútbol 5',
      'Fútbol 7',
      'Fútbol 11',
      'Básquet',
      'Vóley',
      'Tenis',
      'Pádel',
    ];
  }

  // ✅ MÉTODO ORIGINAL - MANTENIDO IGUAL
  static Future<Map<String, dynamic>> createField({
    required String token,
    required int companyId,
    required String fieldName,
    required String fieldType,
    required String fieldSize,
    required int fieldMaxCapacity,
    required double fieldHourPrice,
    required String fieldDescription,
    File? fieldImage,
  }) async {
    try {
      print('🚀 INICIANDO CREACIÓN DE CANCHA');
      print('📍 URL: $baseUrl/fields/create');
      print('🏢 Company ID: $companyId');
      print('⚽ Field Name: $fieldName');
      
      // ✅ USAR JSON NORMAL (como en tu Postman)
      final response = await http.post(
        Uri.parse('$baseUrl/fields/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'company_id': companyId.toString(), // Como string según tu Postman
          'field_name': fieldName,
          'field_type': fieldType,
          'field_size': fieldSize,
          'field_max_capacity': fieldMaxCapacity.toString(), // Como string
          'field_hour_price': fieldHourPrice.toString(), // Como string
          'field_description': fieldDescription,
          'field_img': fieldImage != null ? '/ruta/a/la/img' : '/ruta/default/img', // Placeholder
          'field_calification': '0,0.0', // Valor por defecto
        }),
      );

      print('📤 Request Body: ${json.encode({
        'company_id': companyId.toString(),
        'field_name': fieldName,
        'field_type': fieldType,
        'field_size': fieldSize,
        'field_max_capacity': fieldMaxCapacity.toString(),
        'field_hour_price': fieldHourPrice.toString(),
        'field_description': fieldDescription,
        'field_img': fieldImage != null ? '/ruta/a/la/img' : '/ruta/default/img',
        'field_calification': '0,0.0',
      })}');
      
      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          
          if (responseData['success'] == true || 
              responseData['status'] == true ||
              responseData['message']?.toString().toLowerCase().contains('exitoso') == true) {
            return {
              'success': true,
              'message': responseData['message'] ?? 'Cancha creada exitosamente',
              'data': responseData,
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Error desconocido del servidor',
            };
          }
        } catch (e) {
          print('❌ Error parseando JSON: $e');
          return {
            'success': false,
            'message': 'Error en la respuesta del servidor: $e',
          };
        }
      } else {
        String errorMessage = 'Error del servidor (${response.statusCode})';
        
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // Si no es JSON, mostrar más info del error
          if (response.body.contains('<!DOCTYPE')) {
            errorMessage = 'El servidor devolvió una página HTML en lugar de JSON. Verifica que el endpoint esté configurado correctamente.';
          } else {
            errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en createField: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🆕 NUEVO MÉTODO - CON HORARIOS Y RESERVAS RECURRENTES - CORREGIDO COMPLETO
  static Future<Map<String, dynamic>> createFieldWithSchedules({
    required String token,
    required int companyId,
    required String fieldName,
    required String fieldType,
    required String fieldSize,
    required int fieldMaxCapacity,
    required double fieldHourPrice,
    required String fieldDescription,
    File? fieldImage,
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? recurringReservations,
  }) async {
    try {
      print('🚀 INICIANDO CREACIÓN DE CANCHA CON HORARIOS');
      print('📍 URL: $baseUrl/fields/create');
      
      // Preparar datos básicos
      final Map<String, dynamic> fieldData = {
        'company_id': companyId.toString(),
        'field_name': fieldName,
        'field_type': fieldType,
        'field_size': fieldSize,
        'field_max_capacity': fieldMaxCapacity.toString(),
        'field_hour_price': fieldHourPrice.toString(),
        'field_description': fieldDescription,
        'field_img': fieldImage != null ? '/ruta/a/la/img' : '/ruta/default/img',
        'field_calification': '0,0.0',
      };

      // 🆕 AGREGAR HORARIOS si se proporcionan
      if (schedules != null && schedules.isNotEmpty) {
        fieldData['schedules'] = schedules;
        print('📅 Horarios agregados: ${schedules.length}');
      }

      // 🆕 AGREGAR RESERVAS RECURRENTES si se proporcionan - CORREGIDO
      if (recurringReservations != null && recurringReservations.isNotEmpty) {
        // Obtener usuario actual para llenar created_by_owner_id
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? currentUserId = prefs.getInt('user_id');
        
        if (currentUserId == null) {
          return {
            'success': false,
            'message': 'Usuario no autenticado para crear reservas fijas.',
          };
        }
        
        // Corregir las reservas recurrentes
        final fixedReservations = recurringReservations.map((reservation) {
          final fixed = Map<String, dynamic>.from(reservation);
          fixed['created_by_owner_id'] = currentUserId; // Llenar con ID del usuario actual
          return fixed;
        }).toList();
        
        fieldData['recurring_reservations'] = fixedReservations;
        print('🔄 Reservas recurrentes corregidas: ${fixedReservations.length}');
      }

      print('📤 Request Body: ${json.encode(fieldData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/fields/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(fieldData),
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Cancha creada exitosamente',
          'data': responseData['info'] ?? responseData['data'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error del servidor',
        };
      }
    } catch (e) {
      print('💥 Error en createFieldWithSchedules: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // ✅ MÉTODO ORIGINAL - CORREGIDO - Accede a response['data'] en lugar de response directamente
  static Future<Map<String, dynamic>> getAllFields({String? token}) async {
    try {
      print('🔍 OBTENIENDO TODAS LAS CANCHAS');
      
      Map<String, String> headers = {'Content-Type': 'application/json'};
      
      // Si hay token, agregarlo
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/fields/list'),
        headers: headers,
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          
          // 🔧 CORRECCIÓN: El backend devuelve {success: true, data: [...]}
          // Necesitamos acceder a responseData['data'] no a responseData directamente
          return {
            'success': true,
            'data': responseData['data'] ?? [], // Acceder al campo 'data'
            'message': responseData['message'] ?? 'Canchas obtenidas exitosamente',
          };
        } catch (e) {
          print('❌ Error parseando JSON: $e');
          return {
            'success': false,
            'message': 'Error en la respuesta del servidor: $e',
            'data': [],
          };
        }
      } else {
        String errorMessage = 'Error del servidor (${response.statusCode})';
        
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'data': [],
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en getAllFields: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
      };
    }
  }

  // ✅ MÉTODO ORIGINAL - CORREGIDO - Accede a response['data']
  static Future<Map<String, dynamic>> getFieldsByCompany({
    required String token,
    required int companyId,
  }) async {
    try {
      print('🔍 OBTENIENDO CANCHAS DE LA EMPRESA $companyId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/fields/company/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? [], // 🔧 CORRECCIÓN: Acceder al campo 'data'
          'message': responseData['message'] ?? 'Canchas obtenidas exitosamente',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error del servidor',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
      };
    }
  }

  // 🆕 MÉTODOS PARA HORARIOS - CORREGIDOS CON field_id
  static Future<Map<String, dynamic>> getFieldSchedules(dynamic fieldId) async {
    try {
      // 🔧 VALIDACIÓN: Convertir a int si viene como string
      int? id;
      if (fieldId is String) {
        id = int.tryParse(fieldId);
      } else if (fieldId is int) {
        id = fieldId;
      }
      
      if (id == null || id <= 0) {
        print('❌ FIELD ID INVÁLIDO: $fieldId (convertido a: $id)');
        return {
          'success': false,
          'message': 'ID de cancha no válido: $fieldId',
        };
      }
      
      print('🔍 OBTENIENDO HORARIOS DE CANCHA $id');
      print('📍 URL completa: $baseUrl/fields/$id/schedules');
      
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$id/schedules'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Horarios obtenidos exitosamente',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error obteniendo horarios',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error del servidor (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      print('💥 Error en getFieldSchedules: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getAvailableSlots(dynamic fieldId, String? date) async {
    try {
      // 🔧 VALIDACIONES: Convertir fieldId a int
      int? id;
      if (fieldId is String) {
        id = int.tryParse(fieldId);
      } else if (fieldId is int) {
        id = fieldId;
      }
      
      if (id == null || id <= 0) {
        print('❌ FIELD ID INVÁLIDO: $fieldId (convertido a: $id)');
        return {
          'success': false,
          'message': 'ID de cancha no válido: $fieldId',
        };
      }
      
      if (date == null || date.isEmpty) {
        print('❌ FECHA INVÁLIDA: $date');
        return {
          'success': false,
          'message': 'Fecha no válida: $date',
        };
      }
      
      print('🔍 OBTENIENDO SLOTS DISPONIBLES PARA CANCHA $id EN FECHA $date');
      print('📍 URL completa: $baseUrl/fields/$id/available-slots?date=$date');
      
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$id/available-slots?date=$date'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'meta': data['meta'] ?? {},
          'message': data['message'] ?? 'Slots obtenidos exitosamente',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error obteniendo slots disponibles',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error del servidor (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      print('💥 Error en getAvailableSlots: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🆕 NUEVO - Obtener reservas de una cancha
  static Future<Map<String, dynamic>> getFieldReservations(int fieldId, {String? date}) async {
    try {
      print('🔍 OBTENIENDO RESERVAS DE CANCHA $fieldId');
      
      String url = '$baseUrl/fields/$fieldId/reservations';
      if (date != null && date.isNotEmpty) {
        url += '?date=$date';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Reservas obtenidas exitosamente',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error obteniendo reservas',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error del servidor (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('💥 Error en getFieldReservations: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🆕 HELPER METHODS para generar horarios por defecto
  static List<Map<String, dynamic>> generateDefaultSchedules() {
    List<Map<String, dynamic>> schedules = [];
    
    // Generar horarios para todos los días
    for (int day = 0; day <= 6; day++) { // 0=Domingo, 1=Lunes, etc.
      String startTime, endTime;
      
      // Horarios diferentes para fin de semana
      if (day == 0 || day == 6) { // Domingo o Sábado
        startTime = '08:00:00';
        endTime = '20:00:00';
      } else { // Lunes a Viernes
        startTime = '06:00:00';
        endTime = '22:00:00';
      }
      
      schedules.add({
        'day_of_week': day,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': true,
      });
    }
    
    return schedules;
  }

  static String getDayName(int dayOfWeek) {
    const days = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 
      'Jueves', 'Viernes', 'Sábado'
    ];
    return days[dayOfWeek];
  }

  static String formatTime(String time24) {
    // Convertir de "14:00:00" a "2:00 PM"
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    
    return '$hour:$minute $period';
  }

  static String formatTimeTo24(String time12) {
    // Convertir de "2:00 PM" a "14:00:00"
    final parts = time12.split(' ');
    final timePart = parts[0];
    final period = parts[1];
    
    final timeComponents = timePart.split(':');
    int hour = int.parse(timeComponents[0]);
    final minute = timeComponents[1];
    
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }
}