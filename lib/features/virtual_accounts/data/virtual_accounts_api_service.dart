import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef VirtualAccountsFetchHandler =
    Future<VirtualAccountsApiResult> Function({required String token});

class VirtualAccountsApiService {
  VirtualAccountsApiService._();

  static final VirtualAccountsApiService instance =
      VirtualAccountsApiService._();
  static VirtualAccountsFetchHandler? debugFetchHandler;

  final http.Client _client = http.Client();

  Future<VirtualAccountsApiResult> fetchAccounts({
    required String token,
  }) async {
    final VirtualAccountsFetchHandler? handler = debugFetchHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/virtual-accounts',
    );

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
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        final Map<String, dynamic>? customer =
            data['customer'] is Map<String, dynamic>
                ? data['customer'] as Map<String, dynamic>
                : null;
        final List<VirtualAccountItem> accounts =
            data['accounts'] is List
                ? (data['accounts'] as List<dynamic>)
                    .whereType<Map<String, dynamic>>()
                    .map(VirtualAccountItem.fromJson)
                    .toList(growable: false)
                : const <VirtualAccountItem>[];

        return VirtualAccountsApiResult.success(
          accounts: accounts,
          hasAccounts: data['has_accounts'] == true,
          customerCode: customer?['customer_code']?.toString() ?? '',
          customerEmail: customer?['email']?.toString() ?? '',
          message:
              body['message']?.toString() ??
              'Virtual accounts loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return VirtualAccountsApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return VirtualAccountsApiResult.failure(
        body['message']?.toString() ??
            'We could not load your virtual accounts right now.',
      );
    } catch (_) {
      return const VirtualAccountsApiResult.failure(
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
    debugFetchHandler = null;
  }
}

class VirtualAccountItem {
  const VirtualAccountItem({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.bankSlug,
    required this.isActive,
    required this.createdAt,
    required this.createdLabel,
  });

  factory VirtualAccountItem.fromJson(Map<String, dynamic> json) {
    return VirtualAccountItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      bankSlug: json['bank_slug']?.toString() ?? '',
      isActive: json['is_active'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      createdLabel: json['created_label']?.toString() ?? '',
    );
  }

  final int id;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String bankSlug;
  final bool isActive;
  final DateTime createdAt;
  final String createdLabel;
}

class VirtualAccountsApiResult {
  const VirtualAccountsApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.accounts = const <VirtualAccountItem>[],
    this.hasAccounts = false,
    this.customerCode = '',
    this.customerEmail = '',
    this.message,
  });

  const VirtualAccountsApiResult.success({
    required List<VirtualAccountItem> accounts,
    required bool hasAccounts,
    required String customerCode,
    required String customerEmail,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         accounts: accounts,
         hasAccounts: hasAccounts,
         customerCode: customerCode,
         customerEmail: customerEmail,
         message: message,
       );

  const VirtualAccountsApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const VirtualAccountsApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<VirtualAccountItem> accounts;
  final bool hasAccounts;
  final String customerCode;
  final String customerEmail;
  final String? message;
}
