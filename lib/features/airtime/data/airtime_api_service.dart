import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef AirtimeRecipientsRequestHandler =
    Future<AirtimeRecipientsApiResult> Function({
      required String token,
      required int limit,
    });

typedef AirtimePurchaseRequestHandler =
    Future<AirtimePurchaseApiResult> Function({
      required String token,
      required String networkId,
      required String phoneNumber,
      required int amount,
      required bool saveRecipient,
      required String pin,
    });

class AirtimeApiService {
  AirtimeApiService._();

  static final AirtimeApiService instance = AirtimeApiService._();
  static AirtimeRecipientsRequestHandler? debugRecipientsHandler;
  static AirtimePurchaseRequestHandler? debugPurchaseHandler;

  final http.Client _client = http.Client();

  Future<AirtimeRecipientsApiResult> fetchRecipients({
    required String token,
    int limit = 8,
  }) async {
    final AirtimeRecipientsRequestHandler? handler = debugRecipientsHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/airtime/recipients?limit=$limit',
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
        return AirtimeRecipientsApiResult.success(
          recipients: _extractRecipients(body['recipients']),
          message:
              body['message']?.toString() ?? 'Recipients loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return AirtimeRecipientsApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return AirtimeRecipientsApiResult.failure(
        body['message']?.toString() ??
            'We could not load your saved recipients right now.',
      );
    } catch (_) {
      return const AirtimeRecipientsApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<AirtimePurchaseApiResult> purchaseAirtime({
    required String token,
    required String networkId,
    required String phoneNumber,
    required int amount,
    required bool saveRecipient,
    required String pin,
  }) async {
    final AirtimePurchaseRequestHandler? handler = debugPurchaseHandler;
    if (handler != null) {
      return handler(
        token: token,
        networkId: networkId,
        phoneNumber: phoneNumber,
        amount: amount,
        saveRecipient: saveRecipient,
        pin: pin,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/airtime/purchase',
    );

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
          'Idempotency-Key': _buildIdempotencyKey(
            networkId: networkId,
            phoneNumber: phoneNumber,
            amount: amount,
          ),
        },
        body: jsonEncode(<String, Object>{
          'network': int.tryParse(networkId) ?? 0,
          'phone_number': phoneNumber,
          'amount': amount,
          'save_recipient': saveRecipient,
          'pin': pin,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return AirtimePurchaseApiResult.success(
          message:
              body['message']?.toString() ??
              'Your airtime purchase was completed successfully.',
          reference: body['reference']?.toString() ?? '',
          recentRecipients: _extractRecipients(body['recent_recipients']),
        );
      }

      if (response.statusCode == 401) {
        return AirtimePurchaseApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return AirtimePurchaseApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the airtime form and try again.',
        );
      }

      return AirtimePurchaseApiResult.failure(
        body['message']?.toString() ??
            'We could not complete this airtime purchase right now.',
        reference: body['reference']?.toString() ?? '',
        recentRecipients: _extractRecipients(body['recent_recipients']),
      );
    } catch (_) {
      return const AirtimePurchaseApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<AirtimeSavedRecipient> _extractRecipients(Object? value) {
    if (value is! List) {
      return const <AirtimeSavedRecipient>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(AirtimeSavedRecipient.fromJson)
        .toList(growable: false);
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

  String _buildIdempotencyKey({
    required String networkId,
    required String phoneNumber,
    required int amount,
  }) {
    final String normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D+'), '');
    return 'airtime-$networkId-$normalizedPhone-$amount-${DateTime.now().microsecondsSinceEpoch}';
  }

  static void resetDebugHandlers() {
    debugRecipientsHandler = null;
    debugPurchaseHandler = null;
  }
}

class AirtimeSavedRecipient {
  const AirtimeSavedRecipient({
    required this.id,
    required this.phoneNumber,
    required this.networkId,
    required this.networkName,
    required this.usageCount,
    required this.lastUsedAt,
  });

  factory AirtimeSavedRecipient.fromJson(Map<String, dynamic> json) {
    return AirtimeSavedRecipient(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      phoneNumber: json['phone_number']?.toString() ?? '',
      networkId: json['network']?.toString() ?? '',
      networkName: json['network_name']?.toString() ?? '',
      usageCount: int.tryParse(json['usage_count']?.toString() ?? '') ?? 0,
      lastUsedAt: json['last_used_at']?.toString() ?? '',
    );
  }

  final int id;
  final String phoneNumber;
  final String networkId;
  final String networkName;
  final int usageCount;
  final String lastUsedAt;
}

class AirtimeRecipientsApiResult {
  const AirtimeRecipientsApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.recipients = const <AirtimeSavedRecipient>[],
    this.message,
  });

  const AirtimeRecipientsApiResult.success({
    required List<AirtimeSavedRecipient> recipients,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         recipients: recipients,
         message: message,
       );

  const AirtimeRecipientsApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const AirtimeRecipientsApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<AirtimeSavedRecipient> recipients;
  final String? message;
}

class AirtimePurchaseApiResult {
  const AirtimePurchaseApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.isValidationError,
    this.message,
    this.reference = '',
    this.recentRecipients = const <AirtimeSavedRecipient>[],
    this.fieldErrors = const <String, String>{},
  });

  const AirtimePurchaseApiResult.success({
    required String message,
    required String reference,
    required List<AirtimeSavedRecipient> recentRecipients,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         isValidationError: false,
         message: message,
         reference: reference,
         recentRecipients: recentRecipients,
       );

  const AirtimePurchaseApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        isValidationError: false,
        message: message,
      );

  const AirtimePurchaseApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const AirtimePurchaseApiResult.failure(
    String message, {
    String reference = '',
    List<AirtimeSavedRecipient> recentRecipients =
        const <AirtimeSavedRecipient>[],
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: false,
         message: message,
         reference: reference,
         recentRecipients: recentRecipients,
       );

  final bool isSuccess;
  final bool isUnauthorized;
  final bool isValidationError;
  final String? message;
  final String reference;
  final List<AirtimeSavedRecipient> recentRecipients;
  final Map<String, String> fieldErrors;
}
