// lib/models/bank_account.dart
class BankAccount {
  final int id;
  final String bank;
  final String accountNumber;
  final String accountType;
  final String accountOwner;
  final String? accountCi;
  final String displayName;
  final String formattedNumber;
  final PaymentInfo paymentInfo;
  final bool? isActive;
  final String? accountTypeCategory;

  BankAccount({
    required this.id,
    required this.bank,
    required this.accountNumber,
    required this.accountType,
    required this.accountOwner,
    this.accountCi,
    required this.displayName,
    required this.formattedNumber,
    required this.paymentInfo,
    this.isActive,
    this.accountTypeCategory,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('b_account_bank') || json.containsKey('account_type')) {
      return _fromBackendJson(json);
    } else {
      return _fromOriginalJson(json);
    }
  }

  static BankAccount _fromBackendJson(Map<String, dynamic> json) {
    final bank = json['bank']?.toString() ?? json['b_account_bank']?.toString() ?? '';
    final accountNumber = json['accountNumber']?.toString() ??
        json['b_account_number']?.toString() ?? '';
    final accountType = json['accountType']?.toString() ??
        json['b_account_type']?.toString() ?? '';
    final accountOwner = json['accountOwner']?.toString() ??
        json['b_account_owner']?.toString() ?? '';
    final accountCi = json['ci']?.toString() ?? json['b_account_ci']?.toString();

    final formattedNumber = _formatAccountNumber(accountNumber);

    return BankAccount(
      id: json['id'] is int
          ? json['id']
          : (json['b_account_id'] ?? 0) as int,
      bank: bank,
      accountNumber: accountNumber,
      accountType: accountType,
      accountOwner: accountOwner,
      accountCi: accountCi,
      displayName: '$bank - $accountType',
      formattedNumber: formattedNumber,
      paymentInfo: PaymentInfo(
        banco: bank,
        tipo: accountType,
        numero: formattedNumber,
        titular: accountOwner,
        cedula: accountCi ?? '',
      ),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      accountTypeCategory: json['accountTypeCategory']?.toString() ??
          json['account_type']?.toString() ??
          '',
    );
  }

  static BankAccount _fromOriginalJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int,
      bank: json['bank']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? '',
      accountOwner: json['account_owner']?.toString() ?? '',
      accountCi: json['account_ci']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
      formattedNumber: json['formatted_number']?.toString() ?? '',
      paymentInfo: PaymentInfo.fromJson(
        (json['payment_info'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  static String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 8) return accountNumber;
    return accountNumber.replaceAllMapped(
      RegExp(r'(\d{4})(?=\d)'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank': bank,
      'account_number': accountNumber,
      'account_type': accountType,
      'account_owner': accountOwner,
      'account_ci': accountCi,
      'display_name': displayName,
      'formatted_number': formattedNumber,
      'payment_info': paymentInfo.toJson(),
      'is_active': isActive,
      'account_type_category': accountTypeCategory,
    };
  }

  bool get isAdminAccount {
    return accountTypeCategory == 'admin_collection';
  }

  @override
  String toString() {
    return 'BankAccount(id: $id, bank: $bank, accountNumber: $accountNumber, accountType: $accountType)';
  }
}

class PaymentInfo {
  final String banco;
  final String tipo;
  final String numero;
  final String titular;
  final String cedula;

  PaymentInfo({
    required this.banco,
    required this.tipo,
    required this.numero,
    required this.titular,
    required this.cedula,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      banco: json['banco']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      titular: json['titular']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banco': banco,
      'tipo': tipo,
      'numero': numero,
      'titular': titular,
      'cedula': cedula,
    };
  }

  List<String> get formattedInfo => [
        'Banco: $banco',
        'Tipo: $tipo',
        'Número: $numero',
        'Titular: $titular',
        'Cédula: $cedula',
      ];
}

class PaymentAccountsResponse {
  final bool success;
  final List<BankAccount> data;
  final PaymentMeta meta;
  final String message;
  final int? total;

  PaymentAccountsResponse({
    required this.success,
    required this.data,
    required this.meta,
    required this.message,
    this.total,
  });

  factory PaymentAccountsResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map && json['data']['data'] is List) {
      final accountsData = json['data'];
      final accounts = (accountsData['data'] as List<dynamic>)
          .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
          .toList();

      return PaymentAccountsResponse(
        success: json['status'] == true || json['success'] == true,
        data: accounts,
        meta: PaymentMeta(
          total: accountsData['total'] as int? ?? 0,
          message: json['message']?.toString() ?? 'Cuentas obtenidas exitosamente',
          instructions: [],
        ),
        message: json['message']?.toString() ?? 'Cuentas obtenidas exitosamente',
        total: accountsData['total'] as int?,
      );
    } else {
      return PaymentAccountsResponse(
        success: json['success'] as bool? ?? false,
        data: (json['data'] as List<dynamic>? ?? [])
            .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
            .toList(),
        meta: PaymentMeta.fromJson(
          (json['meta'] as Map<String, dynamic>? ?? {}),
        ),
        message: json['message']?.toString() ?? '',
        total: json['total'] as int?,
      );
    }
  }
}

class PaymentMeta {
  final int total;
  final String message;
  final List<String> instructions;

  PaymentMeta({
    required this.total,
    required this.message,
    required this.instructions,
  });

  factory PaymentMeta.fromJson(Map<String, dynamic> json) {
    return PaymentMeta(
      total: json['total'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
      instructions: (json['instructions'] as List<dynamic>? ?? [])
          .map((item) => item?.toString() ?? '')
          .toList(),
    );
  }
}
