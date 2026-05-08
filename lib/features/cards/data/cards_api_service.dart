import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef CardsOverviewRequestHandler =
    Future<CardsOverviewApiResult> Function({
      required String token,
      required int historyLimit,
    });

typedef CardsGenerateRequestHandler =
    Future<CardsGenerateApiResult> Function({
      required String token,
      required String mode,
      required String optionId,
      required int quantity,
      required String businessName,
      required String pin,
    });

class CardsApiService {
  CardsApiService._();

  static final CardsApiService instance = CardsApiService._();
  static CardsOverviewRequestHandler? debugOverviewHandler;
  static CardsGenerateRequestHandler? debugGenerateHandler;

  static void resetDebugHandlers() {
    debugOverviewHandler = null;
    debugGenerateHandler = null;
  }

  final http.Client _client = http.Client();

  Future<CardsOverviewApiResult> fetchOverview({
    required String token,
    int historyLimit = 12,
  }) async {
    final CardsOverviewRequestHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token, historyLimit: historyLimit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/cards/overview?history_limit=$historyLimit',
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
        return CardsOverviewApiResult.success(
          walletBalance: _toDouble(body['wallet_balance']),
          modes: _extractModes(body['modes']),
          history: _extractHistory(body['history']),
        );
      }

      if (response.statusCode == 401) {
        return CardsOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return CardsOverviewApiResult.failure(
        body['message']?.toString() ??
            'We could not load the cards overview right now.',
      );
    } catch (_) {
      return const CardsOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<CardsGenerateApiResult> generate({
    required String token,
    required String mode,
    required String optionId,
    required int quantity,
    required String businessName,
    required String pin,
  }) async {
    final CardsGenerateRequestHandler? handler = debugGenerateHandler;
    if (handler != null) {
      return handler(
        token: token,
        mode: mode,
        optionId: optionId,
        quantity: quantity,
        businessName: businessName,
        pin: pin,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/cards/generate');

    try {
      final http.Response response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Airplug-App': '1',
            },
            body: jsonEncode(<String, Object>{
              'mode': mode,
              'option_id': optionId,
              'quantity': quantity,
              'business_name': businessName,
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return CardsGenerateApiResult.success(
          message:
              body['message']?.toString() ??
              'Your card request was completed successfully.',
          walletBalance: _toDouble(body['wallet_balance']),
          historyItem: _extractHistoryItem(body['history_item']),
        );
      }

      if (response.statusCode == 401) {
        return CardsGenerateApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return CardsGenerateApiResult.validation(
          message:
              body['message']?.toString() ??
              'Please correct the card details and try again.',
          fieldErrors: _extractFieldErrors(body['errors']),
        );
      }

      return CardsGenerateApiResult.failure(
        body['message']?.toString() ??
            'We could not complete this card request right now.',
        fieldErrors: _extractFieldErrors(body['errors']),
      );
    } on TimeoutException {
      return const CardsGenerateApiResult.failure(
        'The cards request is taking longer than expected. Please wait a moment and check your history before trying again.',
      );
    } catch (_) {
      return const CardsGenerateApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<CardsApiMode> _extractModes(Object? value) {
    if (value is! List) {
      return const <CardsApiMode>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(CardsApiMode.fromJson)
        .toList(growable: false);
  }

  List<CardsApiHistoryItem> _extractHistory(Object? value) {
    if (value is! List) {
      return const <CardsApiHistoryItem>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(CardsApiHistoryItem.fromJson)
        .toList(growable: false);
  }

  CardsApiHistoryItem? _extractHistoryItem(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return CardsApiHistoryItem.fromJson(value);
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

  Map<String, dynamic> _decodeObject(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(body);
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
}

class CardsOverviewApiResult {
  const CardsOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.message,
    required this.walletBalance,
    required this.modes,
    required this.history,
  });

  const CardsOverviewApiResult.success({
    required double walletBalance,
    required List<CardsApiMode> modes,
    required List<CardsApiHistoryItem> history,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         message: '',
         walletBalance: walletBalance,
         modes: modes,
         history: history,
       );

  const CardsOverviewApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        message: message,
        walletBalance: 0,
        modes: const <CardsApiMode>[],
        history: const <CardsApiHistoryItem>[],
      );

  const CardsOverviewApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        message: message,
        walletBalance: 0,
        modes: const <CardsApiMode>[],
        history: const <CardsApiHistoryItem>[],
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final String message;
  final double walletBalance;
  final List<CardsApiMode> modes;
  final List<CardsApiHistoryItem> history;
}

class CardsGenerateApiResult {
  const CardsGenerateApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.message,
    required this.walletBalance,
    required this.historyItem,
    required this.fieldErrors,
  });

  const CardsGenerateApiResult.success({
    required String message,
    required double walletBalance,
    required CardsApiHistoryItem? historyItem,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         message: message,
         walletBalance: walletBalance,
         historyItem: historyItem,
         fieldErrors: const <String, String>{},
       );

  const CardsGenerateApiResult.failure(
    String message, {
    Map<String, String> fieldErrors = const <String, String>{},
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         message: message,
         walletBalance: 0,
         historyItem: null,
         fieldErrors: fieldErrors,
       );

  const CardsGenerateApiResult.validation({
    required String message,
    required Map<String, String> fieldErrors,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         message: message,
         walletBalance: 0,
         historyItem: null,
         fieldErrors: fieldErrors,
       );

  const CardsGenerateApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        message: message,
        walletBalance: 0,
        historyItem: null,
        fieldErrors: const <String, String>{},
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final String message;
  final double walletBalance;
  final CardsApiHistoryItem? historyItem;
  final Map<String, String> fieldErrors;
}

class CardsApiMode {
  const CardsApiMode({
    required this.id,
    required this.label,
    required this.options,
  });

  factory CardsApiMode.fromJson(Map<String, dynamic> json) {
    return CardsApiMode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      options:
          (json['options'] is List)
              ? (json['options'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(CardsApiOption.fromJson)
                  .toList(growable: false)
              : const <CardsApiOption>[],
    );
  }

  final String id;
  final String label;
  final List<CardsApiOption> options;
}

class CardsApiOption {
  const CardsApiOption({
    required this.id,
    required this.label,
    required this.amount,
    required this.meta,
  });

  factory CardsApiOption.fromJson(Map<String, dynamic> json) {
    return CardsApiOption(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      amount:
          (json['amount'] is num)
              ? (json['amount'] as num).toDouble()
              : (double.tryParse(json['amount']?.toString() ?? '') ?? 0),
      meta:
          json['meta'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
              : const <String, dynamic>{},
    );
  }

  final String id;
  final String label;
  final double amount;
  final Map<String, dynamic> meta;
}

class CardsApiHistoryItem {
  const CardsApiHistoryItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.amount,
    required this.category,
    required this.businessName,
    required this.reference,
    required this.status,
    required this.createdAt,
  });

  factory CardsApiHistoryItem.fromJson(Map<String, dynamic> json) {
    return CardsApiHistoryItem(
      id:
          (json['id'] is num)
              ? (json['id'] as num).toInt()
              : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      quantity:
          (json['quantity'] is num)
              ? (json['quantity'] as num).toInt()
              : (int.tryParse(json['quantity']?.toString() ?? '') ?? 0),
      amount:
          (json['amount'] is num)
              ? (json['amount'] as num).toDouble()
              : (double.tryParse(json['amount']?.toString() ?? '') ?? 0),
      category: json['category']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int id;
  final String title;
  final int quantity;
  final double amount;
  final String category;
  final String businessName;
  final String reference;
  final String status;
  final DateTime createdAt;
}
