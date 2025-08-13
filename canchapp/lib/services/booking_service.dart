// lib/services/booking_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Obtener reservas de hoy para una empresa
  static Future<Map<String, dynamic>> getTodayBookings({
    required String token,
    required int companyId,
  }) async {
    try {
      print('📅 OBTENIENDO RESERVAS DE HOY - Empresa: $companyId');
      
      final today = DateTime.now();
      final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('$baseUrl/calendars/company/$companyId/today?date=$todayString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        int totalBookings = 0;
        List<Map<String, dynamic>> todayBookings = [];
        
        if (responseData['success'] == true && responseData['data'] is List) {
          todayBookings = List<Map<String, dynamic>>.from(responseData['data']);
          // Contar solo las reservas confirmadas/reservadas
          totalBookings = todayBookings.where((booking) => 
            booking['calendar_state'] == 'Reservada' || 
            booking['calendar_state'] == 'Confirmada'
          ).length;
        }
        
        return {
          'success': true,
          'data': todayBookings,
          'totalBookings': totalBookings,
          'message': 'Reservas de hoy obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo reservas de hoy',
          'data': [],
          'totalBookings': 0,
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en getTodayBookings: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
        'totalBookings': 0,
      };
    }
  }

  // Obtener próximas reservas
  static Future<Map<String, dynamic>> getUpcomingBookings({
    required String token,
    required int companyId,
    int limit = 5,
  }) async {
    try {
      print('📋 OBTENIENDO PRÓXIMAS RESERVAS - Empresa: $companyId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/calendars/company/$companyId/upcoming?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<Map<String, dynamic>> bookings = [];
        if (responseData['success'] == true && responseData['data'] is List) {
          bookings = List<Map<String, dynamic>>.from(responseData['data']);
        }
        
        // Formatear para mostrar en UI
        final formattedBookings = bookings.map((booking) {
          return {
            'id': booking['calendar_id'],
            'field_name': booking['field_name'] ?? 'Cancha ${booking['field_id']}',
            'client_name': booking['user_name'] ?? 'Cliente',
            'time_range': '${booking['calendar_init_time']} - ${booking['calendar_end_time']}',
            'date': booking['calendar_date'],
            'status': booking['calendar_state'],
          };
        }).toList();
        
        return {
          'success': true,
          'data': formattedBookings,
          'message': 'Próximas reservas obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo próximas reservas',
          'data': [],
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en getUpcomingBookings: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
      };
    }
  }

  // Obtener clientes únicos de una empresa
  static Future<Map<String, dynamic>> getUniqueClients({
    required String token,
    required int companyId,
  }) async {
    try {
      print('👥 OBTENIENDO CLIENTES ÚNICOS - Empresa: $companyId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/calendars/company/$companyId/clients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        int newClientsCount = 0;
        if (responseData['success'] == true && responseData['data'] is List) {
          final clients = List<Map<String, dynamic>>.from(responseData['data']);
          
          // Contar clientes nuevos (con primera reserva en el último mes)
          final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
          newClientsCount = clients.where((client) {
            final firstBookingDate = DateTime.tryParse(client['first_booking_date'] ?? '');
            return firstBookingDate != null && firstBookingDate.isAfter(oneMonthAgo);
          }).length;
        }
        
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'newClientsCount': newClientsCount,
          'message': 'Clientes obtenidos exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo clientes',
          'data': [],
          'newClientsCount': 0,
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en getUniqueClients: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
        'newClientsCount': 0,
      };
    }
  }

  // Crear una nueva reserva
  static Future<Map<String, dynamic>> createBooking({
    required String token,
    required int fieldId,
    required int userId,
    required String bookingDate, // YYYY-MM-DD
    required String startTime, // HH:MM:SS
    required String endTime, // HH:MM:SS
    int? cashClosingId,
    String? transactionId,
  }) async {
    try {
      print('➕ CREANDO NUEVA RESERVA');
      
      final response = await http.post(
        Uri.parse('$baseUrl/calendars/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'field_id': fieldId,
          'user_id': userId,
          'calendar_date': bookingDate,
          'calendar_init_time': startTime,
          'calendar_end_time': endTime,
          'calendar_state': 'Reservada',
          'cash_closing_id': cashClosingId ?? 1,
          'calendar_transaccion': transactionId,
        }),
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Reserva creada exitosamente',
          'data': responseData['data'] ?? {},
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error creando reserva',
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en createBooking: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Actualizar estado de una reserva
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String token,
    required int calendarId,
    required String status,
  }) async {
    try {
      print('🔄 ACTUALIZANDO ESTADO DE RESERVA $calendarId a $status');
      
      final response = await http.put(
        Uri.parse('$baseUrl/calendars/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'calendar_id': calendarId,
          'calendar_state': status,
        }),
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Estado actualizado correctamente',
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error actualizando estado',
        };
      }
    } catch (e) {
      print('💥 EXCEPCIÓN en updateBookingStatus: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}