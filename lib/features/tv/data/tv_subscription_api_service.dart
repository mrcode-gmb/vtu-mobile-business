import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef TvCatalogRequestHandler =
    Future<TvCatalogApiResult> Function({
      required String token,
      required int limit,
    });

typedef TvPlansRequestHandler =
    Future<TvPlansApiResult> Function({
      required String token,
      required String serviceId,
    });

typedef TvValidationRequestHandler =
    Future<TvValidationApiResult> Function({
      required String token,
      required String serviceId,
      required String smartCardNumber,
      required String meterType,
    });

typedef TvPurchaseRequestHandler =
    Future<TvPurchaseApiResult> Function({
      required String token,
      required String serviceId,
      required String smartCardNumber,
      required String meterType,
      required double amount,
      required String phoneNumber,
      required String pin,
      required String variationCode,
      required String planName,
    });

class TvSubscriptionApiService {
  TvSubscriptionApiService._();

  static final TvSubscriptionApiService instance = TvSubscriptionApiService._();
  static TvCatalogRequestHandler? debugCatalogHandler;
  static TvPlansRequestHandler? debugPlansHandler;
  static TvValidationRequestHandler? debugValidationHandler;
  static TvPurchaseRequestHandler? debugPurchaseHandler;

  final http.Client _client = http.Client();

  Future<TvCatalogApiResult> fetchCatalog({
    required String token,
    int limit = 8,
  }) async {
    final TvCatalogRequestHandler? handler = debugCatalogHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/tv/catalog?limit=$limit',
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
        return TvCatalogApiResult.success(
          serviceCharge:
              double.tryParse(body['service_charge']?.toString() ?? '') ?? 100,
          providers: _extractProviders(body['providers']),
          history: _extractHistory(body['history']),
        );
      }

      if (response.statusCode == 401) {
        return TvCatalogApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return TvCatalogApiResult.failure(
        body['message']?.toString() ??
            'We could not load the cable bill page right now.',
      );
    } on TimeoutException {
      return const TvCatalogApiResult.failure(
        'The cable bill page is taking longer than expected to load.',
      );
    } catch (_) {
      return const TvCatalogApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TvPlansApiResult> fetchPlans({
    required String token,
    required String serviceId,
  }) async {
    final TvPlansRequestHandler? handler = debugPlansHandler;
    if (handler != null) {
      return handler(token: token, serviceId: serviceId);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/tv/plans?service_id=$serviceId',
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
        return TvPlansApiResult.success(plans: _extractPlans(body['plans']));
      }

      if (response.statusCode == 401) {
        return TvPlansApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return TvPlansApiResult.failure(
        body['message']?.toString() ??
            'We could not load the cable bouquets right now.',
      );
    } on TimeoutException {
      return const TvPlansApiResult.failure(
        'Cable bouquets are taking longer than expected to load.',
      );
    } catch (_) {
      return const TvPlansApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TvValidationApiResult> validateSubscriber({
    required String token,
    required String serviceId,
    required String smartCardNumber,
    required String meterType,
  }) async {
    final TvValidationRequestHandler? handler = debugValidationHandler;
    if (handler != null) {
      return handler(
        token: token,
        serviceId: serviceId,
        smartCardNumber: smartCardNumber,
        meterType: meterType,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/tv/validate');

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
              'smart_card_number': smartCardNumber,
              'meter_type': meterType,
            }),
          )
          .timeout(const Duration(seconds: 80));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return TvValidationApiResult.success(
          customerName:
              body['customer_name']?.toString() ?? 'Customer Verified',
          message:
              body['message']?.toString() ?? 'Customer validated successfully.',
        );
      }

      if (response.statusCode == 401) {
        return TvValidationApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return TvValidationApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the cable bill form and try again.',
        );
      }

      return TvValidationApiResult.failure(
        body['message']?.toString() ??
            'We could not verify this decoder right now.',
      );
    } on TimeoutException {
      return const TvValidationApiResult.failure(
        'Decoder validation is taking longer than expected. Please try again.',
      );
    } catch (_) {
      return const TvValidationApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TvPurchaseApiResult> purchase({
    required String token,
    required String serviceId,
    required String smartCardNumber,
    required String meterType,
    required double amount,
    required String phoneNumber,
    required String pin,
    required String variationCode,
    required String planName,
  }) async {
    final TvPurchaseRequestHandler? handler = debugPurchaseHandler;
    if (handler != null) {
      return handler(
        token: token,
        serviceId: serviceId,
        smartCardNumber: smartCardNumber,
        meterType: meterType,
        amount: amount,
        phoneNumber: phoneNumber,
        pin: pin,
        variationCode: variationCode,
        planName: planName,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/tv/purchase');

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
                smartCardNumber: smartCardNumber,
                amount: amount,
              ),
            },
            body: jsonEncode(<String, Object>{
              'service_id': serviceId,
              'smart_card_number': smartCardNumber,
              'meter_type': meterType,
              'amount': amount,
              'phone': phoneNumber,
              'pin': pin,
              'variation_code': variationCode,
              'plan_name': planName,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return TvPurchaseApiResult.success(
          message:
              body['message']?.toString() ??
              'Your cable bill was completed successfully.',
          reference: body['reference']?.toString() ?? '',
          providerToken: body['provider_token']?.toString() ?? '',
          historyItem: _extractSingleHistoryItem(body['history_item']),
        );
      }

      if (response.statusCode == 401) {
        return TvPurchaseApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return TvPurchaseApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the cable bill form and try again.',
        );
      }

      return TvPurchaseApiResult.failure(
        body['message']?.toString() ??
            'We could not complete this cable bill right now.',
        reference: body['reference']?.toString() ?? '',
        fieldErrors: _extractFieldErrors(body['errors']),
      );
    } on TimeoutException {
      return const TvPurchaseApiResult.failure(
        'The cable bill request is taking longer than expected. Please check your history before trying again.',
      );
    } catch (_) {
      return const TvPurchaseApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<TvApiProvider> _extractProviders(Object? value) {
    if (value is! List) {
      return const <TvApiProvider>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TvApiProvider.fromJson)
        .toList(growable: false);
  }

  List<TvApiPlan> _extractPlans(Object? value) {
    if (value is! List) {
      return const <TvApiPlan>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TvApiPlan.fromJson)
        .toList(growable: false);
  }

  List<TvApiHistoryItem> _extractHistory(Object? value) {
    if (value is! List) {
      return const <TvApiHistoryItem>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TvApiHistoryItem.fromJson)
        .toList(growable: false);
  }

  TvApiHistoryItem? _extractSingleHistoryItem(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return TvApiHistoryItem.fromJson(value);
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

  String _buildIdempotencyKey({
    required String serviceId,
    required String smartCardNumber,
    required double amount,
  }) {
    final String normalizedCard = smartCardNumber.replaceAll(
      RegExp(r'\D+'),
      '',
    );
    final String amountPart = amount.toStringAsFixed(2);
    return 'tv-$serviceId-$normalizedCard-$amountPart-${DateTime.now().microsecondsSinceEpoch}';
  }

  static void resetDebugHandlers() {
    debugCatalogHandler = null;
    debugPlansHandler = null;
    debugValidationHandler = null;
    debugPurchaseHandler = null;
  }
}

class TvApiProvider {
  const TvApiProvider({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.meterTypes,
    required this.image,
  });

  factory TvApiProvider.fromJson(Map<String, dynamic> json) {
    final Object? rawMeterTypes = json['meter_types'];
    final List<String> meterTypes =
        rawMeterTypes is List
            ? rawMeterTypes
                .map<String>((dynamic item) => item.toString())
                .toList(growable: false)
            : const <String>['prepaid'];

    return TvApiProvider(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? json['id']?.toString() ?? '',
      meterTypes: meterTypes.isEmpty ? const <String>['prepaid'] : meterTypes,
      image: json['image']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String serviceId;
  final List<String> meterTypes;
  final String image;
}

class TvApiPlan {
  const TvApiPlan({
    required this.id,
    required this.variationCode,
    required this.name,
    required this.amount,
  });

  factory TvApiPlan.fromJson(Map<String, dynamic> json) {
    return TvApiPlan(
      id: json['id']?.toString() ?? '',
      variationCode: json['variation_code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Bouquet',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
    );
  }

  final String id;
  final String variationCode;
  final String name;
  final double amount;
}

class TvApiHistoryItem {
  const TvApiHistoryItem({
    required this.id,
    required this.provider,
    required this.plan,
    required this.smartCardNumber,
    required this.amount,
    required this.status,
    required this.reference,
    required this.createdAt,
  });

  factory TvApiHistoryItem.fromJson(Map<String, dynamic> json) {
    return TvApiHistoryItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      provider: json['provider']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'Cable Bill',
      smartCardNumber: json['smart_card_number']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'Pending',
      reference: json['reference']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final int id;
  final String provider;
  final String plan;
  final String smartCardNumber;
  final double amount;
  final String status;
  final String reference;
  final String createdAt;
}

class TvCatalogApiResult {
  const TvCatalogApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.serviceCharge,
    required this.providers,
    required this.history,
    this.message,
  });

  const TvCatalogApiResult.success({
    required double serviceCharge,
    required List<TvApiProvider> providers,
    required List<TvApiHistoryItem> history,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         serviceCharge: serviceCharge,
         providers: providers,
         history: history,
       );

  const TvCatalogApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        serviceCharge: 100,
        providers: const <TvApiProvider>[],
        history: const <TvApiHistoryItem>[],
        message: message,
      );

  const TvCatalogApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        serviceCharge: 100,
        providers: const <TvApiProvider>[],
        history: const <TvApiHistoryItem>[],
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final double serviceCharge;
  final List<TvApiProvider> providers;
  final List<TvApiHistoryItem> history;
  final String? message;
}

class TvPlansApiResult {
  const TvPlansApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.plans,
    this.message,
  });

  const TvPlansApiResult.success({required List<TvApiPlan> plans})
    : this._(isSuccess: true, isUnauthorized: false, plans: plans);

  const TvPlansApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        plans: const <TvApiPlan>[],
        message: message,
      );

  const TvPlansApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        plans: const <TvApiPlan>[],
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final List<TvApiPlan> plans;
  final String? message;
}

class TvValidationApiResult {
  const TvValidationApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.customerName,
    required this.fieldErrors,
    this.message,
  });

  const TvValidationApiResult.success({
    required String customerName,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         customerName: customerName,
         fieldErrors: const <String, String>{},
         message: message,
       );

  const TvValidationApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        customerName: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  const TvValidationApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         customerName: '',
         fieldErrors: fieldErrors,
         message: message,
       );

  const TvValidationApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        customerName: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final String customerName;
  final Map<String, String> fieldErrors;
  final String? message;
}

class TvPurchaseApiResult {
  const TvPurchaseApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.reference,
    required this.providerToken,
    required this.fieldErrors,
    this.historyItem,
    this.message,
  });

  const TvPurchaseApiResult.success({
    required String message,
    required String reference,
    required String providerToken,
    TvApiHistoryItem? historyItem,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         reference: reference,
         providerToken: providerToken,
         historyItem: historyItem,
         fieldErrors: const <String, String>{},
         message: message,
       );

  const TvPurchaseApiResult.failure(
    String message, {
    String reference = '',
    Map<String, String> fieldErrors = const <String, String>{},
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         reference: reference,
         providerToken: '',
         fieldErrors: fieldErrors,
         message: message,
       );

  const TvPurchaseApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         reference: '',
         providerToken: '',
         fieldErrors: fieldErrors,
         message: message,
       );

  const TvPurchaseApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        reference: '',
        providerToken: '',
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final String reference;
  final String providerToken;
  final TvApiHistoryItem? historyItem;
  final Map<String, String> fieldErrors;
  final String? message;
}
