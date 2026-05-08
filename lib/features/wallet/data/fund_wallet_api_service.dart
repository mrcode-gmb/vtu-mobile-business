import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef FundWalletOverviewHandler =
    Future<FundWalletOverviewApiResult> Function({required String token});
typedef FundWalletSubmitHandler =
    Future<FundWalletSubmitApiResult> Function({
      required String token,
      required int amount,
      required String accountName,
      required String bankName,
    });

class FundWalletApiService {
  FundWalletApiService._();

  static final FundWalletApiService instance = FundWalletApiService._();
  static FundWalletOverviewHandler? debugOverviewHandler;
  static FundWalletSubmitHandler? debugSubmitHandler;

  final http.Client _client = http.Client();

  Future<FundWalletOverviewApiResult> fetchOverview({
    required String token,
  }) async {
    final FundWalletOverviewHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/fund-wallet');

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
        return FundWalletOverviewApiResult.success(
          overview: _buildOverview(body),
          message:
              body['message']?.toString() ??
              'Fund wallet overview loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return FundWalletOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return FundWalletOverviewApiResult.failure(
        body['message']?.toString() ??
            'We could not load your funding details right now.',
      );
    } catch (_) {
      return const FundWalletOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<FundWalletSubmitApiResult> submitManualFunding({
    required String token,
    required int amount,
    required String accountName,
    required String bankName,
  }) async {
    final FundWalletSubmitHandler? handler = debugSubmitHandler;
    if (handler != null) {
      return handler(
        token: token,
        amount: amount,
        accountName: accountName,
        bankName: bankName,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/fund-wallet/manual',
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
        body: jsonEncode(<String, Object>{
          'amount': amount,
          'account_name': accountName,
          'bank_name': bankName,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        return FundWalletSubmitApiResult.success(
          historyItem: FundWalletHistoryItem.fromJson(
            data['history_item'] is Map<String, dynamic>
                ? data['history_item'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ??
              'Your manual funding has been submitted successfully.',
        );
      }

      if (response.statusCode == 401) {
        return FundWalletSubmitApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return FundWalletSubmitApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the funding details and try again.',
        );
      }

      return FundWalletSubmitApiResult.failure(
        body['message']?.toString() ??
            'We could not submit your funding request right now.',
      );
    } catch (_) {
      return const FundWalletSubmitApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  FundWalletOverview _buildOverview(Map<String, dynamic> body) {
    final Map<String, dynamic> data =
        body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : <String, dynamic>{};

    final List<FundWalletReceivingAccount> accounts =
        data['receiving_accounts'] is List
            ? (data['receiving_accounts'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(FundWalletReceivingAccount.fromJson)
                .toList(growable: false)
            : const <FundWalletReceivingAccount>[];

    final List<FundWalletHistoryItem> history =
        data['history'] is List
            ? (data['history'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(FundWalletHistoryItem.fromJson)
                .toList(growable: false)
            : const <FundWalletHistoryItem>[];

    return FundWalletOverview(
      walletBalance: _toDouble(data['wallet_balance']),
      receivingAccounts: accounts,
      history: history,
      hasReceivingAccounts: data['has_receiving_accounts'] == true,
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

  Map<String, String> _extractFieldErrors(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const <String, String>{};
    }

    final Map<String, String> fieldErrors = <String, String>{};
    value.forEach((String key, dynamic raw) {
      if (raw is List && raw.isNotEmpty) {
        fieldErrors[key] = raw.first.toString();
      } else if (raw is String && raw.trim().isNotEmpty) {
        fieldErrors[key] = raw.trim();
      }
    });
    return fieldErrors;
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static void resetDebugHandlers() {
    debugOverviewHandler = null;
    debugSubmitHandler = null;
  }
}

class FundWalletOverview {
  const FundWalletOverview({
    required this.walletBalance,
    required this.receivingAccounts,
    required this.history,
    required this.hasReceivingAccounts,
  });

  final double walletBalance;
  final List<FundWalletReceivingAccount> receivingAccounts;
  final List<FundWalletHistoryItem> history;
  final bool hasReceivingAccounts;
}

class FundWalletReceivingAccount {
  const FundWalletReceivingAccount({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
  });

  factory FundWalletReceivingAccount.fromJson(Map<String, dynamic> json) {
    return FundWalletReceivingAccount(
      id: json['id']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
    );
  }

  final String id;
  final String accountNumber;
  final String accountName;
  final String bankName;
}

class FundWalletHistoryItem {
  const FundWalletHistoryItem({
    required this.id,
    required this.reference,
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.type,
    required this.typeLabel,
    required this.paymentMethod,
    required this.createdAt,
    required this.createdLabel,
  });

  factory FundWalletHistoryItem.fromJson(Map<String, dynamic> json) {
    return FundWalletHistoryItem(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Pending',
      type: json['type']?.toString() ?? 'manual',
      typeLabel: json['type_label']?.toString() ?? 'Manual Transfer',
      paymentMethod: json['payment_method']?.toString() ?? 'Bank Transfer',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      createdLabel: json['created_label']?.toString() ?? '',
    );
  }

  final String id;
  final String reference;
  final double amount;
  final String status;
  final String statusLabel;
  final String type;
  final String typeLabel;
  final String paymentMethod;
  final DateTime createdAt;
  final String createdLabel;

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FundWalletOverviewApiResult {
  const FundWalletOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.message,
  });

  const FundWalletOverviewApiResult.success({
    required FundWalletOverview overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         message: message,
       );

  const FundWalletOverviewApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const FundWalletOverviewApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final FundWalletOverview? overview;
  final String? message;
}

class FundWalletSubmitApiResult {
  const FundWalletSubmitApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.isValidationError,
    this.historyItem,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const FundWalletSubmitApiResult.success({
    required FundWalletHistoryItem historyItem,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         isValidationError: false,
         historyItem: historyItem,
         message: message,
       );

  const FundWalletSubmitApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        isValidationError: false,
        message: message,
      );

  const FundWalletSubmitApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: true,
         message: message,
         fieldErrors: fieldErrors,
       );

  const FundWalletSubmitApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        isValidationError: false,
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final bool isValidationError;
  final FundWalletHistoryItem? historyItem;
  final String? message;
  final Map<String, String> fieldErrors;
}
