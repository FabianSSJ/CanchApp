// lib/services/bank_account_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bank_account.dart';

class BankAccountService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Cambia por tu URL de API

  /// Obtener todas las cuentas bancarias disponibles para pago
  static Future<Map<String, dynamic>> getPaymentAccounts() async {
    try {
      print('🏦 Obteniendo cuentas bancarias para pago...');

      final response = await http.get(
        Uri.parse('$baseUrl/payment-accounts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta cuentas bancarias - Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Cuentas bancarias obtenidas exitosamente');
          return {
            'success': true,
            'data': PaymentAccountsResponse.fromJson(data),
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo cuentas bancarias',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo cuentas bancarias: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🆕 NUEVO MÉTODO: Obtener solo cuentas del admin para pagos
  static Future<Map<String, dynamic>> getAdminPaymentAccounts() async {
    try {
      print('🏦 Obteniendo cuentas del admin para pagos...');

      final response = await http.get(
        Uri.parse('$baseUrl/bank_accounts/admin-payment-accounts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta cuentas admin - Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Compatibilidad con tu formato de API (status o success)
        if (data['status'] == true || data['success'] == true) {
          print('✅ Cuentas del admin obtenidas exitosamente');
          return {
            'success': true,
            'data': PaymentAccountsResponse.fromJson(data),
            'message': data['message'] ?? 'Cuentas del admin obtenidas exitosamente'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo cuentas del admin',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo cuentas del admin: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener detalles de una cuenta bancaria específica
  static Future<Map<String, dynamic>> getAccountDetails(int accountId) async {
    try {
      print('🏦 Obteniendo detalles de cuenta $accountId...');

      final response = await http.get(
        Uri.parse('$baseUrl/payment-accounts/$accountId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Respuesta detalles cuenta - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Detalles de cuenta obtenidos exitosamente');
          return {
            'success': true,
            'data': BankAccountDetails.fromJson(data['data']),
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error obteniendo detalles de cuenta',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Cuenta bancaria no encontrada',
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Excepción obteniendo detalles de cuenta: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Formatear número de cuenta para mejor visualización
  static String formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 8) return accountNumber;
    return accountNumber.replaceAllMapped(
      RegExp(r'(\d{4})(?=\d)'),
      (match) => '${match.group(0)}-',
    );
  }

  /// Obtener icono según el banco
  static String getBankIcon(String bankName) {
    switch (bankName.toLowerCase()) {
      case 'banco pichincha':
        return '🏦';
      case 'banco de loja':
        return '🏛️';
      case 'coopmego':
        return '🤝';
      case 'banco guayaquil':
        return '🏪';
      case 'cacpe loja':
        return '💼';
      default:
        return '🏦';
    }
  }

  /// Obtener color según el banco
  static int getBankColor(String bankName) {
    switch (bankName.toLowerCase()) {
      case 'banco pichincha':
        return 0xFF1976D2; // Azul
      case 'banco de loja':
        return 0xFF388E3C; // Verde
      case 'coopmego':
        return 0xFFFF9800; // Naranja
      case 'banco guayaquil':
        return 0xFFD32F2F; // Rojo
      case 'cacpe loja':
        return 0xFF7B1FA2; // Púrpura
      default:
        return 0xFF616161; // Gris
    }
  }
}

/// Clase para detalles extendidos de cuenta bancaria
class BankAccountDetails {
  final int id;
  final String bank;
  final String accountNumber;
  final String accountType;
  final String accountOwner;
  final String accountCi;
  final String displayName;
  final String formattedNumber;
  final List<String> paymentInstructions;
  final List<String> transferSteps;

  BankAccountDetails({
    required this.id,
    required this.bank,
    required this.accountNumber,
    required this.accountType,
    required this.accountOwner,
    required this.accountCi,
    required this.displayName,
    required this.formattedNumber,
    required this.paymentInstructions,
    required this.transferSteps,
  });

  factory BankAccountDetails.fromJson(Map<String, dynamic> json) {
    return BankAccountDetails(
      id: json['id'] as int,
      bank: json['bank'] as String,
      accountNumber: json['account_number'] as String,
      accountType: json['account_type'] as String,
      accountOwner: json['account_owner'] as String,
      accountCi: json['account_ci'] as String,
      displayName: json['display_name'] as String,
      formattedNumber: json['formatted_number'] as String,
      paymentInstructions: (json['payment_instructions'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      transferSteps: (json['transfer_steps'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }
}