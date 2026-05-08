import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef BillCatalogRequestHandler =
    Future<BillCatalogApiResult> Function({
      required String token,
      required int limit,
    });

typedef BillValidateMeterRequestHandler =
    Future<BillValidateMeterApiResult> Function({
      required String token,
      required String serviceId,
      required String meterNumber,
      required String meterType,
    });

typedef BillPurchaseRequestHandler =
    Future<BillPurchaseApiResult> Function({
      required String token,
      required String serviceId,
      required String meterNumber,
      required String meterType,
      required double amount,
      required String phoneNumber,
      required String pin,
    });

class BillPaymentApiService {
  BillPaymentApiService._();

  static final BillPaymentApiService instance = BillPaymentApiService._();
  static BillCatalogRequestHandler? debugCatalogHandler;
  static BillValidateMeterRequestHandler? debugValidateMeterHandler;
  static BillPurchaseRequestHandler? debugPurchaseHandler;

  final http.Client _client = http.Client();

  Future<BillCatalogApiResult> fetchCatalog({
    required String token,
    int limit = 20,
  }) async {
    final BillCatalogRequestHandler? handler = debugCatalogHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/bills/catalog?limit=$limit',
    );

    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Airplug-App': '1',
            },
          )
          .timeout(const Duration(seconds: 80));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return BillCatalogApiResult.success(
          serviceCharge:
              double.tryParse(body['service_charge']?.toString() ?? '') ?? 100,
          minAmount:
              double.tryParse(body['min_amount']?.toString() ?? '') ?? 100,
          maxAmount:
              double.tryParse(body['max_amount']?.toString() ?? '') ?? 500000,
          providers: _extractProviders(body['providers']),
          history: _extractHistory(body['history']),
        );
      }

      if (response.statusCode == 401) {
        return BillCatalogApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return BillCatalogApiResult.failure(
        body['message']?.toString() ??
            'We could not load the bill payment page right now.',
      );
    } on TimeoutException {
      return const BillCatalogApiResult.failure(
        'The bill payment page is taking longer than expected to load.',
      );
    } catch (_) {
      return const BillCatalogApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<BillValidateMeterApiResult> validateMeter({
    required String token,
    required String serviceId,
    required String meterNumber,
    required String meterType,
  }) async {
    final BillValidateMeterRequestHandler? handler = debugValidateMeterHandler;
    if (handler != null) {
      return handler(
        token: token,
        serviceId: serviceId,
        meterNumber: meterNumber,
        meterType: meterType,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/bills/validate-meter',
    );

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
              'service_id': serviceId,
              'meter_number': meterNumber,
              'meter_type': meterType,
            }),
          )
          .timeout(const Duration(seconds: 80));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        return BillValidateMeterApiResult.success(
          customerName:
              data['owner_name']?.toString() ??
              data['customer_name']?.toString() ??
              'Customer Verified',
          address: data['address']?.toString() ?? '',
          message:
              body['message']?.toString() ?? 'Meter validated successfully.',
        );
      }

      if (response.statusCode == 401) {
        return BillValidateMeterApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return BillValidateMeterApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the meter details and try again.',
        );
      }

      return BillValidateMeterApiResult.failure(
        body['message']?.toString() ??
            'We could not validate this meter right now.',
      );
    } on TimeoutException {
      return const BillValidateMeterApiResult.failure(
        'Meter validation is taking longer than expected. Please try again.',
      );
    } catch (_) {
      return const BillValidateMeterApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<BillPurchaseApiResult> purchase({
    required String token,
    required String serviceId,
    required String meterNumber,
    required String meterType,
    required double amount,
    required String phoneNumber,
    required String pin,
  }) async {
    final BillPurchaseRequestHandler? handler = debugPurchaseHandler;
    if (handler != null) {
      return handler(
        token: token,
        serviceId: serviceId,
        meterNumber: meterNumber,
        meterType: meterType,
        amount: amount,
        phoneNumber: phoneNumber,
        pin: pin,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/bills/purchase');

    try {
      final http.Response response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Airplug-App': '1',
              'Idempotency-Key': _buildIdempotencyKey(
                serviceId: serviceId,
                meterNumber: meterNumber,
                amount: amount,
              ),
            },
            body: jsonEncode(<String, Object>{
              'service_id': serviceId,
              'meter_number': meterNumber,
              'meter_type': meterType,
              'amount': amount,
              'phone': phoneNumber,
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return BillPurchaseApiResult.success(
          status: BillPurchaseStatus.successful,
          message:
              body['message']?.toString() ??
              'Your electricity bill was completed successfully.',
          reference: body['reference']?.toString() ?? '',
          historyItem: _extractSingleHistoryItem(body['history_item']),
        );
      }

      if (response.statusCode == 202) {
        return BillPurchaseApiResult.success(
          status: BillPurchaseStatus.processing,
          message:
              body['message']?.toString() ??
              'Your electricity bill is being processed.',
          reference: body['reference']?.toString() ?? '',
          historyItem: _extractSingleHistoryItem(body['history_item']),
        );
      }

      if (response.statusCode == 401) {
        return BillPurchaseApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return BillPurchaseApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the bill form and try again.',
        );
      }

      return BillPurchaseApiResult.failure(
        _extractProviderFailureMessage(body) ??
            body['message']?.toString() ??
            'We could not complete this bill payment right now.',
        reference: body['reference']?.toString() ?? '',
        fieldErrors: _extractFieldErrors(body['errors']),
      );
    } on TimeoutException {
      return const BillPurchaseApiResult.failure(
        'The bill payment request is taking longer than expected. Please check your history before trying again.',
      );
    } catch (_) {
      return const BillPurchaseApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<BillApiProvider> _extractProviders(Object? value) {
    if (value is! List) {
      return const <BillApiProvider>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(BillApiProvider.fromJson)
        .toList(growable: false);
  }

  List<BillApiHistoryItem> _extractHistory(Object? value) {
    if (value is! List) {
      return const <BillApiHistoryItem>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(BillApiHistoryItem.fromJson)
        .toList(growable: false);
  }

  BillApiHistoryItem? _extractSingleHistoryItem(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return BillApiHistoryItem.fromJson(value);
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

    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      final String message = _extractMessageFromRaw(value);
      if (message.isNotEmpty) {
        return <String, dynamic>{'message': message};
      }
    }

    return <String, dynamic>{};
  }

  String _extractMessageFromRaw(String value) {
    final String stripped =
        value
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (stripped.isEmpty) {
      return '';
    }

    return stripped.length > 240 ? stripped.substring(0, 240) : stripped;
  }

  String? _extractProviderFailureMessage(Map<String, dynamic> body) {
    final Object? providerResponse = body['provider_response'];
    if (providerResponse is! Map<String, dynamic>) {
      return null;
    }

    final String summary = providerResponse['summary']?.toString().trim() ?? '';
    if (summary.isNotEmpty) {
      return summary;
    }

    final String message = providerResponse['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }

    final String raw = providerResponse['raw_body']?.toString().trim() ?? '';
    if (raw.isNotEmpty) {
      return _extractMessageFromRaw(raw);
    }

    return null;
  }

  String _buildIdempotencyKey({
    required String serviceId,
    required String meterNumber,
    required double amount,
  }) {
    final String normalizedMeter = meterNumber.replaceAll(RegExp(r'\D+'), '');
    final String amountPart = amount.toStringAsFixed(2);
    return 'bill-$serviceId-$normalizedMeter-$amountPart-${DateTime.now().microsecondsSinceEpoch}';
  }

  static void resetDebugHandlers() {
    debugCatalogHandler = null;
    debugValidateMeterHandler = null;
    debugPurchaseHandler = null;
  }
}

class BillApiProvider {
  const BillApiProvider({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.meterTypes,
  });

  factory BillApiProvider.fromJson(Map<String, dynamic> json) {
    final Object? rawMeterTypes = json['meter_types'];
    final List<String> meterTypes =
        rawMeterTypes is List
            ? rawMeterTypes
                .map<String>((dynamic item) => item.toString())
                .toList(growable: false)
            : const <String>['prepaid', 'postpaid'];

    return BillApiProvider(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      meterTypes:
          meterTypes.isEmpty
              ? const <String>['prepaid', 'postpaid']
              : meterTypes,
    );
  }

  final String id;
  final String name;
  final String serviceId;
  final List<String> meterTypes;
}

class BillApiHistoryItem {
  const BillApiHistoryItem({
    required this.id,
    required this.provider,
    required this.meterNumber,
    required this.meterType,
    required this.amount,
    required this.billAmount,
    required this.charges,
    required this.status,
    required this.phoneNumber,
    required this.reference,
    required this.createdAt,
  });

  factory BillApiHistoryItem.fromJson(Map<String, dynamic> json) {
    return BillApiHistoryItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      provider: json['provider']?.toString() ?? 'Electricity',
      meterNumber: json['meter_number']?.toString() ?? '',
      meterType: json['meter_type']?.toString() ?? 'Prepaid',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      billAmount: double.tryParse(json['bill_amount']?.toString() ?? '') ?? 0,
      charges: double.tryParse(json['charges']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'failed',
      phoneNumber: json['phone_number']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final int id;
  final String provider;
  final String meterNumber;
  final String meterType;
  final double amount;
  final double billAmount;
  final double charges;
  final String status;
  final String phoneNumber;
  final String reference;
  final String createdAt;
}

class BillCatalogApiResult {
  const BillCatalogApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.serviceCharge,
    required this.minAmount,
    required this.maxAmount,
    required this.providers,
    required this.history,
    this.message,
  });

  const BillCatalogApiResult.success({
    required double serviceCharge,
    required double minAmount,
    required double maxAmount,
    required List<BillApiProvider> providers,
    required List<BillApiHistoryItem> history,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         serviceCharge: serviceCharge,
         minAmount: minAmount,
         maxAmount: maxAmount,
         providers: providers,
         history: history,
       );

  const BillCatalogApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        serviceCharge: 100,
        minAmount: 100,
        maxAmount: 500000,
        providers: const <BillApiProvider>[],
        history: const <BillApiHistoryItem>[],
        message: message,
      );

  const BillCatalogApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        serviceCharge: 100,
        minAmount: 100,
        maxAmount: 500000,
        providers: const <BillApiProvider>[],
        history: const <BillApiHistoryItem>[],
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final double serviceCharge;
  final double minAmount;
  final double maxAmount;
  final List<BillApiProvider> providers;
  final List<BillApiHistoryItem> history;
  final String? message;
}

class BillValidateMeterApiResult {
  const BillValidateMeterApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.customerName,
    required this.address,
    required this.fieldErrors,
    this.message,
  });

  const BillValidateMeterApiResult.success({
    required String customerName,
    required String address,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         customerName: customerName,
         address: address,
         fieldErrors: const <String, String>{},
         message: message,
       );

  const BillValidateMeterApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        customerName: '',
        address: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  const BillValidateMeterApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         customerName: '',
         address: '',
         fieldErrors: fieldErrors,
         message: message,
       );

  const BillValidateMeterApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        customerName: '',
        address: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final String customerName;
  final String address;
  final Map<String, String> fieldErrors;
  final String? message;
}

enum BillPurchaseStatus { successful, processing, failed }

class BillPurchaseApiResult {
  const BillPurchaseApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.status,
    required this.reference,
    required this.fieldErrors,
    this.historyItem,
    this.message,
  });

  const BillPurchaseApiResult.success({
    required BillPurchaseStatus status,
    required String message,
    required String reference,
    BillApiHistoryItem? historyItem,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         status: status,
         reference: reference,
         historyItem: historyItem,
         fieldErrors: const <String, String>{},
         message: message,
       );

  const BillPurchaseApiResult.failure(
    String message, {
    String reference = '',
    Map<String, String> fieldErrors = const <String, String>{},
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         status: BillPurchaseStatus.failed,
         reference: reference,
         fieldErrors: fieldErrors,
         message: message,
       );

  const BillPurchaseApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         status: BillPurchaseStatus.failed,
         reference: '',
         fieldErrors: fieldErrors,
         message: message,
       );

  const BillPurchaseApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        status: BillPurchaseStatus.failed,
        reference: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final BillPurchaseStatus status;
  final String reference;
  final BillApiHistoryItem? historyItem;
  final Map<String, String> fieldErrors;
  final String? message;
}
