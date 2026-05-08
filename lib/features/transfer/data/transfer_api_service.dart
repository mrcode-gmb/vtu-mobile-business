import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef TransferOverviewHandler =
    Future<TransferOverviewApiResult> Function({
      required String token,
      required int limit,
    });
typedef TransferValidateRecipientHandler =
    Future<TransferValidateRecipientApiResult> Function({
      required String token,
      required String username,
    });
typedef TransferSubmitHandler =
    Future<TransferSubmitApiResult> Function({
      required String token,
      required String username,
      required double amount,
      required String pin,
      required String note,
    });

class TransferApiService {
  TransferApiService._();

  static final TransferApiService instance = TransferApiService._();
  static TransferOverviewHandler? debugOverviewHandler;
  static TransferValidateRecipientHandler? debugValidateRecipientHandler;
  static TransferSubmitHandler? debugSubmitHandler;

  final http.Client _client = http.Client();

  Future<TransferOverviewApiResult> fetchOverview({
    required String token,
    int limit = 10,
  }) async {
    final TransferOverviewHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/transfers/overview?limit=$limit',
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
        return TransferOverviewApiResult.success(
          overview: TransferOverview.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ??
              'Transfer overview loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return TransferOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return TransferOverviewApiResult.failure(
        body['message']?.toString() ??
            'We could not load transfer details right now.',
      );
    } catch (_) {
      return const TransferOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TransferValidateRecipientApiResult> validateRecipient({
    required String token,
    required String username,
  }) async {
    final TransferValidateRecipientHandler? handler =
        debugValidateRecipientHandler;
    if (handler != null) {
      return handler(token: token, username: username);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/transfers/validate-user',
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
        body: jsonEncode(<String, Object>{'username': username}),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        return TransferValidateRecipientApiResult.success(
          recipientName: data['name']?.toString() ?? 'PTS DATA User',
          username: data['username']?.toString() ?? username,
          message:
              body['message']?.toString() ??
              'Recipient validated successfully.',
        );
      }

      if (response.statusCode == 401) {
        return TransferValidateRecipientApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return TransferValidateRecipientApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              _firstValidationMessage(body['errors']) ??
              'We could not validate this PTS DATA user.',
        );
      }

      return TransferValidateRecipientApiResult.failure(
        body['message']?.toString() ??
            'We could not validate this PTS DATA user.',
      );
    } catch (_) {
      return const TransferValidateRecipientApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TransferSubmitApiResult> submitTransfer({
    required String token,
    required String username,
    required double amount,
    required String pin,
    required String note,
  }) async {
    final TransferSubmitHandler? handler = debugSubmitHandler;
    if (handler != null) {
      return handler(
        token: token,
        username: username,
        amount: amount,
        pin: pin,
        note: note,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/transfers');

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
          'username': username,
          'amount': amount,
          'pin': pin,
          'note': note,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        return TransferSubmitApiResult.success(
          walletBalance: _toDouble(data['wallet_balance']),
          reference: data['reference']?.toString() ?? '',
          recipientName: data['recipient_name']?.toString() ?? 'PTS DATA User',
          note: data['note']?.toString() ?? note,
          historyItem:
              data['history_item'] is Map<String, dynamic>
                  ? TransferApiHistoryItem.fromJson(
                    data['history_item'] as Map<String, dynamic>,
                  )
                  : null,
          message:
              body['message']?.toString() ?? 'Transfer completed successfully.',
        );
      }

      if (response.statusCode == 401) {
        return TransferSubmitApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422 || response.statusCode == 400) {
        return TransferSubmitApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              _firstValidationMessage(body['errors']) ??
              'We could not complete this transfer right now.',
        );
      }

      return TransferSubmitApiResult.failure(
        body['message']?.toString() ??
            'We could not complete this transfer right now.',
      );
    } catch (_) {
      return const TransferSubmitApiResult.failure(
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
    debugValidateRecipientHandler = null;
    debugSubmitHandler = null;
  }
}

class TransferOverview {
  const TransferOverview({
    required this.walletBalance,
    required this.minAmount,
    required this.history,
  });

  factory TransferOverview.fromJson(Map<String, dynamic> json) {
    return TransferOverview(
      walletBalance: _toDouble(json['wallet_balance']),
      minAmount: _toDouble(json['min_amount']),
      history:
          json['history'] is List
              ? (json['history'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(TransferApiHistoryItem.fromJson)
                  .toList(growable: false)
              : const <TransferApiHistoryItem>[],
    );
  }

  final double walletBalance;
  final double minAmount;
  final List<TransferApiHistoryItem> history;
}

class TransferApiHistoryItem {
  const TransferApiHistoryItem({
    required this.id,
    required this.username,
    required this.recipientName,
    required this.amount,
    required this.status,
    required this.reference,
    required this.createdAt,
  });

  factory TransferApiHistoryItem.fromJson(Map<String, dynamic> json) {
    return TransferApiHistoryItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? 'PTS DATA User',
      amount: _toDouble(json['amount']),
      status: json['status']?.toString() ?? 'Successful',
      reference: json['reference']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  final int id;
  final String username;
  final String recipientName;
  final double amount;
  final String status;
  final String reference;
  final DateTime? createdAt;
}

class TransferOverviewApiResult {
  const TransferOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.message,
  });

  const TransferOverviewApiResult.success({
    required TransferOverview overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         message: message,
       );

  const TransferOverviewApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  const TransferOverviewApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final TransferOverview? overview;
  final String? message;
}

class TransferValidateRecipientApiResult {
  const TransferValidateRecipientApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.fieldErrors,
    required this.recipientName,
    required this.username,
    this.message,
  });

  const TransferValidateRecipientApiResult.success({
    required String recipientName,
    required String username,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         fieldErrors: const <String, String>{},
         recipientName: recipientName,
         username: username,
         message: message,
       );

  const TransferValidateRecipientApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        fieldErrors: const <String, String>{},
        recipientName: '',
        username: '',
        message: message,
      );

  const TransferValidateRecipientApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         fieldErrors: fieldErrors,
         recipientName: '',
         username: '',
         message: message,
       );

  const TransferValidateRecipientApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        fieldErrors: const <String, String>{},
        recipientName: '',
        username: '',
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final Map<String, String> fieldErrors;
  final String recipientName;
  final String username;
  final String? message;
}

class TransferSubmitApiResult {
  const TransferSubmitApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.fieldErrors,
    required this.walletBalance,
    required this.reference,
    required this.recipientName,
    required this.note,
    this.historyItem,
    this.message,
  });

  const TransferSubmitApiResult.success({
    required double walletBalance,
    required String reference,
    required String recipientName,
    required String note,
    TransferApiHistoryItem? historyItem,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         fieldErrors: const <String, String>{},
         walletBalance: walletBalance,
         reference: reference,
         recipientName: recipientName,
         note: note,
         historyItem: historyItem,
         message: message,
       );

  const TransferSubmitApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        fieldErrors: const <String, String>{},
        walletBalance: 0,
        reference: '',
        recipientName: '',
        note: '',
        message: message,
      );

  const TransferSubmitApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         fieldErrors: fieldErrors,
         walletBalance: 0,
         reference: '',
         recipientName: '',
         note: '',
         message: message,
       );

  const TransferSubmitApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        fieldErrors: const <String, String>{},
        walletBalance: 0,
        reference: '',
        recipientName: '',
        note: '',
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final Map<String, String> fieldErrors;
  final double walletBalance;
  final String reference;
  final String recipientName;
  final String note;
  final TransferApiHistoryItem? historyItem;
  final String? message;
}

double _toDouble(Object? value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

Map<String, String> _extractFieldErrors(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const <String, String>{};
  }

  final Map<String, String> errors = <String, String>{};
  for (final MapEntry<String, dynamic> entry in value.entries) {
    final dynamic current = entry.value;
    if (current is List && current.isNotEmpty) {
      errors[entry.key] = current.first.toString();
      continue;
    }
    if (current != null) {
      errors[entry.key] = current.toString();
    }
  }

  return errors;
}

String? _firstValidationMessage(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  for (final dynamic current in value.values) {
    if (current is List && current.isNotEmpty) {
      return current.first.toString();
    }
    if (current != null) {
      return current.toString();
    }
  }

  return null;
}
