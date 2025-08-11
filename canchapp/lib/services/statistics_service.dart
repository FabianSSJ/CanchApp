// lib/services/statistics_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatisticsService {
  static const String baseUrl = 'http://localhost:3000';

  // Obtener estadísticas del dashboard usando tu backend
  static Future<Map<String, dynamic>> getDashboardStats({
    required String token,
    required int companyId,
  }) async {
    try {
      print('📈 OBTENIENDO ESTADÍSTICAS DEL DASHBOARD - Empresa: $companyId');
      
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
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          return {
            'success': true,
            'data': data,
            'todayBookings': data['today_bookings'] ?? 0,
            'monthlyIncome': double.tryParse(data['monthly_income']?.toString() ?? '0') ?? 0.0,
            'activeFields': data['active_fields'] ?? 0,
            'newClients': data['new_clients'] ?? 0,
            'totalReservations': data['total_reservations'] ?? 0,
            'completedReservations': data['completed_reservations'] ?? 0,
            'cancelledReservations': data['cancelled_reservations'] ?? 0,
            'message': 'Estadísticas del dashboard obtenidas exitosamente',
          };
        }
      }
      
      // Si falla, retornar valores por defecto
      return {
        'success': false,
        'message': 'Error obteniendo estadísticas del dashboard',
        'data': {},
        'todayBookings': 0,
        'monthlyIncome': 0.0,
        'activeFields': 0,
        'newClients': 0,
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getDashboardStats: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': {},
        'todayBookings': 0,
        'monthlyIncome': 0.0,
        'activeFields': 0,
        'newClients': 0,
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
      };
    }
  }

  // Obtener ingresos mensuales
  static Future<Map<String, dynamic>> getMonthlyIncome({
    required String token,
    required int companyId,
    int? year,
    int? month,
  }) async {
    try {
      final currentDate = DateTime.now();
      final targetYear = year ?? currentDate.year;
      final targetMonth = month ?? currentDate.month;
      
      print('💰 OBTENIENDO INGRESOS MENSUALES - Empresa: $companyId, Mes: $targetMonth/$targetYear');
      
      final response = await http.get(
        Uri.parse('$baseUrl/cash-closings/company/$companyId/monthly-income?year=$targetYear&month=$targetMonth'),
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
            'data': data,
            'totalIncome': double.tryParse(data['total_income']?.toString() ?? '0') ?? 0.0,
            'message': 'Ingresos mensuales obtenidos exitosamente',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Error obteniendo ingresos mensuales',
        'data': {},
        'totalIncome': 0.0,
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getMonthlyIncome: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': {},
        'totalIncome': 0.0,
      };
    }
  }

  // Obtener comparativa mensual
  static Future<Map<String, dynamic>> getMonthlyComparison({
    required String token,
    required int companyId,
  }) async {
    try {
      print('📊 OBTENIENDO COMPARATIVA MENSUAL - Empresa: $companyId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/cash-closings/company/$companyId/monthly-comparison'),
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
            'data': data,
            'currentMonthIncome': double.tryParse(data['current_month']?.toString() ?? '0') ?? 0.0,
            'previousMonthIncome': double.tryParse(data['previous_month']?.toString() ?? '0') ?? 0.0,
            'growthPercentage': double.tryParse(data['growth_percentage']?.toString() ?? '0') ?? 0.0,
            'message': 'Comparativa mensual obtenida exitosamente',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Error obteniendo comparativa mensual',
        'data': {},
        'currentMonthIncome': 0.0,
        'previousMonthIncome': 0.0,
        'growthPercentage': 0.0,
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getMonthlyComparison: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': {},
        'currentMonthIncome': 0.0,
        'previousMonthIncome': 0.0,
        'growthPercentage': 0.0,
      };
    }
  }

  // Obtener rendimiento por cancha
  static Future<Map<String, dynamic>> getFieldPerformance({
    required String token,
    required int companyId,
    String? period,
  }) async {
    try {
      print('📈 OBTENIENDO RENDIMIENTO POR CANCHA - Empresa: $companyId');
      
      String url = '$baseUrl/fieldss/company/$companyId/performance';
      if (period != null) {
        url += '?period=$period';
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
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'message': 'Rendimiento por cancha obtenido exitosamente',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Error obteniendo rendimiento por cancha',
        'data': [],
      };
    } catch (e) {
      print('💥 EXCEPCIÓN en getFieldPerformance: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': [],
      };
    }
  }

  // Generar datos simulados para el gráfico semanal cuando no hay datos
  static Map<String, dynamic> generateWeeklyStatsPlaceholder() {
    final List<Map<String, dynamic>> weeklyData = [
      {'day': 'Lun', 'bookings': 0, 'income': 0.0},
      {'day': 'Mar', 'bookings': 0, 'income': 0.0},
      {'day': 'Mié', 'bookings': 0, 'income': 0.0},
      {'day': 'Jue', 'bookings': 0, 'income': 0.0},
      {'day': 'Vie', 'bookings': 0, 'income': 0.0},
      {'day': 'Sáb', 'bookings': 0, 'income': 0.0},
      {'day': 'Dom', 'bookings': 0, 'income': 0.0},
    ];
    
    return {
      'success': true,
      'data': weeklyData,
      'chartData': weeklyData,
      'message': 'Datos semanales (sin reservas aún)',
    };
  }

  // Obtener estadísticas semanales
  static Future<Map<String, dynamic>> getWeeklyStats({
    required String token,
    required int companyId,
    String? weekStart,
  }) async {
    try {
      print('📊 OBTENIENDO ESTADÍSTICAS SEMANALES - Empresa: $companyId');
      
      String url = '$baseUrl/calendars/company/$companyId/weekly-stats';
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
          if (responseData['data'] is List) {
            chartData = List<Map<String, dynamic>>.from(responseData['data']);
          }
          
          // Si no hay datos, generar placeholder
          if (chartData.isEmpty) {
            return generateWeeklyStatsPlaceholder();
          }
          
          return {
            'success': true,
            'data': responseData['data'],
            'chartData': chartData,
            'message': 'Estadísticas semanales obtenidas exitosamente',
          };
        }
      }
      
      // Si falla, retornar datos placeholder
      return generateWeeklyStatsPlaceholder();
    } catch (e) {
      print('💥 EXCEPCIÓN en getWeeklyStats: $e');
      return generateWeeklyStatsPlaceholder();
    }
  }

  // Métodos de utilidad para formatear datos (funcionan sin backend)
  static List<Map<String, dynamic>> formatForLineChart(List<dynamic> data, String xKey, String yKey) {
    return data.map((item) => {
      'x': item[xKey],
      'y': double.tryParse(item[yKey]?.toString() ?? '0') ?? 0.0,
    }).toList();
  }

  static List<Map<String, dynamic>> formatForBarChart(List<dynamic> data, String labelKey, String valueKey) {
    return data.map((item) => {
      'label': item[labelKey]?.toString() ?? '',
      'value': double.tryParse(item[valueKey]?.toString() ?? '0') ?? 0.0,
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
    
    List<String> colors = [];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }
}