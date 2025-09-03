// lib/services/statistics_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatisticsService {
  static const String baseUrl = 'http://104.248.75.98:3000';

  // CORREGIDO: Obtener estadísticas del dashboard
  static Future<Map<String, dynamic>> getDashboardStats({
    required String token,
    required int companyId,
  }) async {
    try {
      print('📊 OBTENIENDO ESTADÍSTICAS DEL DASHBOARD - Empresa: $companyId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/statistics/company/$companyId/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          // CORREGIDO: Los datos vienen directamente en el root de la respuesta
          return {
            'success': true,
            'fieldsReservedToday': responseData['fieldsReservedToday'] ?? 0,
            'dailyIncome': (responseData['dailyIncome'] is num) 
              ? (responseData['dailyIncome'] as num).toDouble() 
              : 0.0,
            'activeFields': responseData['activeFields'] ?? 0,
            'totalClients': responseData['totalClients'] ?? 0,
            'totalReservations': responseData['totalReservations'] ?? 0,
            'completedReservations': responseData['completedReservations'] ?? 0,
            'cancelledReservations': responseData['cancelledReservations'] ?? 0,
            'message': responseData['message'] ?? 'Estadísticas obtenidas exitosamente',
          };
        }
      }
      
      // Si falla, retornar valores por defecto seguros
      return {
        'success': false,
        'message': 'Error obteniendo estadísticas del dashboard',
        'fieldsReservedToday': 0,
        'dailyIncome': 0.0,
        'activeFields': 0,
        'totalClients': 0,
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getDashboardStats: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'fieldsReservedToday': 0,
        'dailyIncome': 0.0,
        'activeFields': 0,
        'totalClients': 0,
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
      };
    }
  }

  // CORREGIDO: Obtener estadísticas semanales 
  static Future<Map<String, dynamic>> getWeeklyStats({
    required String token,
    required int companyId,
    String? weekStart,
  }) async {
    try {
      print('📈 OBTENIENDO ESTADÍSTICAS SEMANALES - Empresa: $companyId');
      
      // CORREGIDO: URL cambiada de /calendars a /statistics
      String url = '$baseUrl/statistics/company/$companyId/weekly-stats';
      if (weekStart != null) {
        url += '?week_start=$weekStart';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          List<Map<String, dynamic>> chartData = [];
          if (responseData['chartData'] is List) {
            chartData = List<Map<String, dynamic>>.from(responseData['chartData']);
          }
          
          // Si no hay datos, generar placeholder
          if (chartData.isEmpty) {
            return _generateWeeklyStatsPlaceholder();
          }
          
          return {
            'success': true,
            'chartData': chartData,
            'total': responseData['total'] ?? 0,
            'message': responseData['message'] ?? 'Estadísticas semanales obtenidas exitosamente',
          };
        }
      }
      
      // Si falla, retornar datos placeholder
      return _generateWeeklyStatsPlaceholder();
    } catch (e) {
      print('💥 EXCEPCIÓN en getWeeklyStats: $e');
      return _generateWeeklyStatsPlaceholder();
    }
  }

  // CORREGIDO: Obtener ingresos por período específico
  static Future<Map<String, dynamic>> getIncomeByPeriod({
    required String token,
    required int companyId,
    String period = 'day', // day, week, month, year
  }) async {
    try {
      print('💰 OBTENIENDO INGRESOS POR PERÍODO - Empresa: $companyId, Período: $period');
      
      final response = await http.get(
        Uri.parse('$baseUrl/statistics/company/$companyId/income?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          return {
            'success': true,
            'totalIncome': (data['totalIncome'] is num) 
              ? (data['totalIncome'] as num).toDouble() 
              : 0.0,
            'confirmedReservations': data['confirmedReservations'] ?? 0,
            'uniqueClients': data['uniqueClients'] ?? 0,
            'avgPricePerReservation': (data['avgPricePerReservation'] is num) 
              ? (data['avgPricePerReservation'] as num).toDouble() 
              : 0.0,
            'period': data['period'] ?? period,
            'periodLabel': data['periodLabel'] ?? 'Ingresos',
            'message': responseData['message'] ?? 'Ingresos obtenidos exitosamente',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Error obteniendo ingresos',
        'totalIncome': 0.0,
        'confirmedReservations': 0,
        'uniqueClients': 0,
        'avgPricePerReservation': 0.0,
        'period': period,
        'periodLabel': 'Ingresos',
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getIncomeByPeriod: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'totalIncome': 0.0,
        'confirmedReservations': 0,
        'uniqueClients': 0,
        'avgPricePerReservation': 0.0,
        'period': period,
        'periodLabel': 'Ingresos',
      };
    }
  }

  // CORREGIDO: Obtener rendimiento por cancha
  static Future<Map<String, dynamic>> getFieldPerformance({
    required String token,
    required int companyId,
    String period = 'month',
  }) async {
    try {
      print('📊 OBTENIENDO RENDIMIENTO POR CANCHA - Empresa: $companyId, Período: $period');
      
      final response = await http.get(
        Uri.parse('$baseUrl/statistics/company/$companyId/fields-performance?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'period': responseData['period'] ?? period,
            'message': responseData['message'] ?? 'Rendimiento obtenido exitosamente',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Error obteniendo rendimiento por cancha',
        'data': [],
        'period': period,
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getFieldPerformance: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
        'period': period,
      };
    }
  }

  // MÉTODO PRIVADO: Generar datos placeholder para estadísticas semanales
  static Map<String, dynamic> _generateWeeklyStatsPlaceholder() {
    final List<Map<String, dynamic>> chartData = [
      {'day': 'Lunes', 'reservations': 0, 'income': 0.0},
      {'day': 'Martes', 'reservations': 0, 'income': 0.0},
      {'day': 'Miércoles', 'reservations': 0, 'income': 0.0},
      {'day': 'Jueves', 'reservations': 0, 'income': 0.0},
      {'day': 'Viernes', 'reservations': 0, 'income': 0.0},
      {'day': 'Sábado', 'reservations': 0, 'income': 0.0},
      {'day': 'Domingo', 'reservations': 0, 'income': 0.0},
    ];
    
    return {
      'success': true,
      'chartData': chartData,
      'total': 0,
      'message': 'Sin datos esta semana',
    };
  }

  // MÉTODOS DE UTILIDAD para formatear datos
  static List<Map<String, dynamic>> formatForLineChart(List<dynamic> data, String xKey, String yKey) {
    if (data.isEmpty) return [];
    
    return data.map((item) {
      if (item is! Map) return {'x': '', 'y': 0.0};
      
      return {
        'x': item[xKey]?.toString() ?? '',
        'y': _parseDouble(item[yKey]),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> formatForBarChart(List<dynamic> data, String labelKey, String valueKey) {
    if (data.isEmpty) return [];
    
    return data.map((item) {
      if (item is! Map) return {'label': '', 'value': 0.0};
      
      return {
        'label': item[labelKey]?.toString() ?? '',
        'value': _parseDouble(item[valueKey]),
      };
    }).toList();
  }

  static List<String> getChartColors(int count) {
    const baseColors = [
      '#059669',
      '#0891b2',
      '#dc2626',
      '#d97706',
      '#7c3aed',
      '#db2777',
      '#059212',
      '#1e40af',
    ];
    
    if (count <= 0) return [];
    
    List<String> colors = [];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }

  // MÉTODO PRIVADO: Parse seguro de double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // MÉTODO PARA DEBUGGING: Validar respuesta del backend
  static void logResponse(String endpoint, Map<String, dynamic> response) {
    print('🔍 RESPONSE DEBUG for $endpoint:');
    print('  - success: ${response['success']}');
    print('  - message: ${response['message']}');
    print('  - keys: ${response.keys.toList()}');
    
    response.forEach((key, value) {
      if (key != 'success' && key != 'message') {
        print('  - $key: $value (${value.runtimeType})');
      }
    });
  }
}