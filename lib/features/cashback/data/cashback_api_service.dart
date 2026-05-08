import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef CashbackOverviewHandler =
    Future<CashbackOverviewApiResult> Function({required String token});
typedef CashbackConvertHandler =
    Future<CashbackConvertApiResult> Function({
      required String token,
      required double amount,
      required String pin,
    });

class CashbackApiService {
  CashbackApiService._();

  static final CashbackApiService instance = CashbackApiService._();
  static CashbackOverviewHandler? debugOverviewHandler;
  static CashbackConvertHandler? debugConvertHandler;

  final http.Client _client = http.Client();

  Future<CashbackOverviewApiResult> fetchOverview({
    required String token,
  }) async {
    final CashbackOverviewHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/cashback');

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
        return CashbackOverviewApiResult.success(
          overview: CashbackOverview.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ?? 'Cashback loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return CashbackOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return CashbackOverviewApiResult.failure(
        body['message']?.toString() ?? 'We could not load cashback right now.',
      );
    } catch (_) {
      return const CashbackOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<CashbackConvertApiResult> convertToWallet({
    required String token,
    required double amount,
    required String pin,
  }) async {
    final CashbackConvertHandler? handler = debugConvertHandler;
    if (handler != null) {
      return handler(token: token, amount: amount, pin: pin);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/cashback/convert',
    );

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, Object>{'amount': amount, 'pin': pin}),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return CashbackConvertApiResult.success(
          overview: CashbackOverview.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          reference:
              body['data'] is Map<String, dynamic>
                  ? (body['data'] as Map<String, dynamic>)['reference']
                          ?.toString() ??
                      ''
                  : '',
          convertedAmount:
              body['data'] is Map<String, dynamic>
                  ? _toDouble(
                    (body['data'] as Map<String, dynamic>)['converted_amount'],
                  )
                  : amount,
          message:
              body['message']?.toString() ?? 'Cashback converted successfully.',
        );
      }

      if (response.statusCode == 401) {
        return CashbackConvertApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422 || response.statusCode == 400) {
        return CashbackConvertApiResult.failure(
          body['message']?.toString() ??
              _firstValidationMessage(body['errors']) ??
              'We could not convert cashback right now.',
        );
      }

      return CashbackConvertApiResult.failure(
        body['message']?.toString() ??
            'We could not convert cashback right now.',
      );
    } catch (_) {
      return const CashbackConvertApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
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

  static void resetDebugHandlers() {
    debugOverviewHandler = null;
    debugConvertHandler = null;
  }
}

class CashbackOverview {
  const CashbackOverview({
    required this.balance,
    required this.totalEarned,
    required this.totalConverted,
    required this.walletBalance,
    required this.recentTransactions,
  });

  factory CashbackOverview.fromJson(Map<String, dynamic> json) {
    return CashbackOverview(
      balance: _toDouble(json['balance']),
      totalEarned: _toDouble(json['total_earned']),
      totalConverted: _toDouble(json['total_converted']),
      walletBalance: _toDouble(json['wallet_balance']),
      recentTransactions:
          json['recent_transactions'] is List
              ? (json['recent_transactions'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(CashbackApiTransaction.fromJson)
                  .toList(growable: false)
              : const <CashbackApiTransaction>[],
    );
  }

  final double balance;
  final double totalEarned;
  final double totalConverted;
  final double walletBalance;
  final List<CashbackApiTransaction> recentTransactions;
}

class CashbackApiTransaction {
  const CashbackApiTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.reference,
    required this.createdAt,
    required this.balanceBefore,
    required this.balanceAfter,
  });

  factory CashbackApiTransaction.fromJson(Map<String, dynamic> json) {
    return CashbackApiTransaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      description: json['description']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      balanceBefore: _toDouble(json['balance_before']),
      balanceAfter: _toDouble(json['balance_after']),
    );
  }

  final int id;
  final String type;
  final double amount;
  final String description;
  final String transactionType;
  final String reference;
  final DateTime? createdAt;
  final double balanceBefore;
  final double balanceAfter;
}

class CashbackOverviewApiResult {
  const CashbackOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.message,
  });

  const CashbackOverviewApiResult.success({
    required CashbackOverview overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         message: message,
       );

  const CashbackOverviewApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const CashbackOverviewApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final CashbackOverview? overview;
  final String? message;
}

class CashbackConvertApiResult {
  const CashbackConvertApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.reference,
    this.convertedAmount,
    this.message,
  });

  const CashbackConvertApiResult.success({
    required CashbackOverview overview,
    required String reference,
    required double convertedAmount,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         reference: reference,
         convertedAmount: convertedAmount,
         message: message,
       );

  const CashbackConvertApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const CashbackConvertApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final CashbackOverview? overview;
  final String? reference;
  final double? convertedAmount;
  final String? message;
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _firstValidationMessage(Object? value) {
  if (value is Map) {
    for (final Object? entry in value.values) {
      if (entry is List && entry.isNotEmpty) {
        return entry.first?.toString();
      }
    }
  }

  return null;
}
