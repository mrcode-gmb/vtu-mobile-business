import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef DashboardOverviewRequestHandler =
    Future<DashboardOverviewApiResult> Function({required String token});

class DashboardApiService {
  DashboardApiService._();

  static final DashboardApiService instance = DashboardApiService._();
  static DashboardOverviewRequestHandler? debugOverviewHandler;

  final http.Client _client = http.Client();

  Future<DashboardOverviewApiResult> fetchOverview({
    required String token,
  }) async {
    final DashboardOverviewRequestHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/dashboard');

    try {
      final http.Response response = await _client.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
        },
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return DashboardOverviewApiResult.success(
          overview: _buildOverview(body),
          message:
              body['message']?.toString() ?? 'Dashboard loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return DashboardOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return DashboardOverviewApiResult.failure(
        body['message']?.toString() ??
            'We could not load your dashboard right now.',
      );
    } catch (_) {
      return const DashboardOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  DashboardOverview _buildOverview(Map<String, dynamic> body) {
    final Map<String, dynamic> data =
        body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : <String, dynamic>{};

    final List<DashboardVirtualAccount> accounts =
        data['virtual_accounts'] is List
            ? (data['virtual_accounts'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(DashboardVirtualAccount.fromJson)
                .toList(growable: false)
            : const <DashboardVirtualAccount>[];

    return DashboardOverview(
      userName: data['user_name']?.toString() ?? 'USER',
      walletBalance: _toDouble(data['wallet_balance']),
      cashbackBalance: _toDouble(data['cashback_balance']),
      totalCashbackEarned: _toDouble(data['total_cashback_earned']),
      monthlySpend: _toDouble(data['monthly_spend']),
      recentTransactions:
          data['recent_transactions'] is List
              ? (data['recent_transactions'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(DashboardRecentTransaction.fromJson)
                  .toList(growable: false)
              : const <DashboardRecentTransaction>[],
      virtualAccounts: accounts,
    );
  }

  Map<String, dynamic> _decodeObject(String value) {
    if (value.isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static void resetDebugHandlers() {
    debugOverviewHandler = null;
  }
}

class DashboardOverview {
  const DashboardOverview({
    required this.userName,
    required this.walletBalance,
    required this.cashbackBalance,
    required this.totalCashbackEarned,
    required this.monthlySpend,
    required this.recentTransactions,
    required this.virtualAccounts,
  });

  final String userName;
  final double walletBalance;
  final double cashbackBalance;
  final double totalCashbackEarned;
  final double monthlySpend;
  final List<DashboardRecentTransaction> recentTransactions;
  final List<DashboardVirtualAccount> virtualAccounts;
}

class DashboardRecentTransaction {
  const DashboardRecentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    required this.description,
    required this.reference,
    this.date,
  });

  factory DashboardRecentTransaction.fromJson(Map<String, dynamic> json) {
    return DashboardRecentTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _dashboardToDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
    );
  }

  final String id;
  final String type;
  final double amount;
  final String status;
  final String direction;
  final String description;
  final String reference;
  final DateTime? date;
}

double _dashboardToDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class DashboardVirtualAccount {
  const DashboardVirtualAccount({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.bankSlug,
    required this.isActive,
  });

  factory DashboardVirtualAccount.fromJson(Map<String, dynamic> json) {
    return DashboardVirtualAccount(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      bankSlug: json['bank_slug']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  final int id;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String bankSlug;
  final bool isActive;
}

class DashboardOverviewApiResult {
  const DashboardOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.message,
  });

  const DashboardOverviewApiResult.success({
    required DashboardOverview overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         message: message,
       );

  const DashboardOverviewApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const DashboardOverviewApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final DashboardOverview? overview;
  final String? message;
}
