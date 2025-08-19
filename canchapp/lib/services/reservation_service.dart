// lib/services/reservation_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReservationService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Cambia por tu URL de API
  
  /// Crear una nueva reserva con comprobante de pago
  static Future<Map<String, dynamic>> createReservation({
    required int fieldId,
    required int userId,
    required String date,
    required String startTime,
    required String endTime,
    required double paymentAmount,
    required File receiptImage,
  }) async {
    try {
      print('🔄 Creando reserva...');
      print('Field ID: $fieldId, User ID: $userId');
      print('Fecha: $date, Hora: $startTime - $endTime');
      print('Monto: \$${paymentAmount.toStringAsFixed(2)}');

      // Crear MultipartRequest para subir imagen
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/calendars/create'),
      );

      // Agregar campos de texto
      request.fields.addAll({
        'field_id': fieldId.toString(),
        'user_id': userId.toString(),
        'calendar_date': date,
        'calendar_init_time': startTime,
        'calendar_end_time': endTime,
        'calendar_transaccion': paymentAmount.toString(),
      });

      // Agregar imagen del comprobante
      String fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt_image',
          receiptImage.path,
          filename: fileName,
        ),
      );

      print('📤 Enviando solicitud de reserva...');
      
      // Enviar solicitud
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Respuesta recibida - Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status' para compatibilidad
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Reserva creada exitosamente');
          return {
            'success': true,
            'message': data['message'] ?? 'Reserva creada exitosamente',
            'data': data['info'] ?? data['data'], // 🔥 FIX: Verificar 'info' también
          };
        } else {
          print('❌ Error en la respuesta: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Error desconocido',
          };
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción creando reserva: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener horarios disponibles para una fecha específica
  static Future<Map<String, dynamic>> getAvailableTimeSlots({
    required int fieldId,
    required String date,
  }) async {
    try {
      print('🔍 Obteniendo horarios disponibles...');
      print('Field ID: $fieldId, Fecha: $date');

      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId/available-slots?date=$date'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta horarios - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status'
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Horarios obtenidos exitosamente');
          return {
            'success': true,
            'data': data['data'] ?? data['info'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo horarios',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo horarios: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener reservas del usuario
  static Future<Map<String, dynamic>> getUserReservations(int userId) async {
    try {
      print('🔍 Obteniendo reservas del usuario: $userId');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/calendars/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Respuesta reservas - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status'
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Reservas obtenidas exitosamente');
          return {
            'success': true,
            'data': data['data'] ?? data['info'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo reservas',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo reservas: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Cancelar una reserva
  static Future<Map<String, dynamic>> cancelReservation(int reservationId) async {
    try {
      print('🚫 Cancelando reserva: $reservationId');

      final response = await http.put(
        Uri.parse('$baseUrl/reservations/$reservationId/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta cancelación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status'
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Reserva cancelada exitosamente');
          return {
            'success': true,
            'message': data['message'] ?? 'Reserva cancelada exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error cancelando reserva',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción cancelando reserva: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener detalles de una reserva específica
  static Future<Map<String, dynamic>> getReservationDetails(int reservationId) async {
    try {
      print('🔍 Obteniendo detalles de reserva: $reservationId');

      final response = await http.get(
        Uri.parse('$baseUrl/reservations/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta detalles - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status'
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Detalles obtenidos exitosamente');
          return {
            'success': true,
            'data': data['data'] ?? data['info'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo detalles',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo detalles: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Verificar disponibilidad de un slot específico
  static Future<Map<String, dynamic>> checkSlotAvailability({
    required int fieldId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      print('✅ Verificando disponibilidad...');
      print('Field: $fieldId, Fecha: $date, Hora: $startTime-$endTime');

      final response = await http.post(
        Uri.parse('$baseUrl/reservations/check-availability'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'field_id': fieldId,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
        }),
      );

      print('📥 Respuesta disponibilidad - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'success': true,
          'available': data['available'] ?? false,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'available': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción verificando disponibilidad: $e');
      return {
        'success': false,
        'available': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener estadísticas de reservas (para admin)
  static Future<Map<String, dynamic>> getReservationStats() async {
    try {
      print('📊 Obteniendo estadísticas de reservas...');

      final response = await http.get(
        Uri.parse('$baseUrl/reservations/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta estadísticas - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔥 FIX: Verificar tanto 'success' como 'status'
        bool isSuccess = data['success'] == true || data['status'] == true;
        
        if (isSuccess) {
          print('✅ Estadísticas obtenidas exitosamente');
          return {
            'success': true,
            'data': data['data'] ?? data['info'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo estadísticas',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo estadísticas: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Helper para convertir string de tiempo a formato API
  static String formatTimeForApi(String timeString) {
    // Convierte "06:00" a "06:00:00"
    if (timeString.length == 5) {
      return '$timeString:00';
    }
    return timeString;
  }

  /// Helper para validar formato de fecha
  static bool isValidDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper para validar formato de hora
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }
}