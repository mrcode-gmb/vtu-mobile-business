import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef DataCatalogRequestHandler =
    Future<DataCatalogApiResult> Function({
      required String token,
      required int recipientLimit,
    });

typedef DataRecipientsRequestHandler =
    Future<DataRecipientsApiResult> Function({
      required String token,
      required int limit,
    });

typedef DataPurchaseRequestHandler =
    Future<DataPurchaseApiResult> Function({
      required String token,
      required String networkId,
      required String dataType,
      required String dataPlanId,
      required String phoneNumber,
      required double amount,
      required String validity,
      required bool saveRecipient,
      required String pin,
    });

class DataApiService {
  DataApiService._();

  static final DataApiService instance = DataApiService._();
  static DataCatalogRequestHandler? debugCatalogHandler;
  static DataRecipientsRequestHandler? debugRecipientsHandler;
  static DataPurchaseRequestHandler? debugPurchaseHandler;

  final http.Client _client = http.Client();

  Future<DataCatalogApiResult> fetchCatalog({
    required String token,
    int recipientLimit = 8,
  }) async {
    final DataCatalogRequestHandler? handler = debugCatalogHandler;
    if (handler != null) {
      return handler(token: token, recipientLimit: recipientLimit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/data/catalog?limit=$recipientLimit',
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
        return DataCatalogApiResult.success(
          providerChannel: body['provider_channel']?.toString() ?? 'primary',
          networks: _extractNetworks(body['networks']),
          recentRecipients: _extractRecipients(body['recent_recipients']),
        );
      }

      if (response.statusCode == 401) {
        return DataCatalogApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return DataCatalogApiResult.failure(
        body['message']?.toString() ??
            'We could not load the data catalog right now.',
      );
    } catch (_) {
      return const DataCatalogApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<DataRecipientsApiResult> fetchRecipients({
    required String token,
    int limit = 50,
  }) async {
    final DataRecipientsRequestHandler? handler = debugRecipientsHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/data/recipients?limit=$limit',
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
        return DataRecipientsApiResult.success(
          recipients: _extractRecipients(body['recipients']),
        );
      }

      if (response.statusCode == 401) {
        return DataRecipientsApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return DataRecipientsApiResult.failure(
        body['message']?.toString() ??
            'We could not load your saved recipients right now.',
      );
    } catch (_) {
      return const DataRecipientsApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<DataPurchaseApiResult> purchaseData({
    required String token,
    required String networkId,
    required String dataType,
    required String dataPlanId,
    required String phoneNumber,
    required double amount,
    required String validity,
    required bool saveRecipient,
    required String pin,
  }) async {
    final DataPurchaseRequestHandler? handler = debugPurchaseHandler;
    if (handler != null) {
      return handler(
        token: token,
        networkId: networkId,
        dataType: dataType,
        dataPlanId: dataPlanId,
        phoneNumber: phoneNumber,
        amount: amount,
        validity: validity,
        saveRecipient: saveRecipient,
        pin: pin,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/data/purchase');

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
                networkId: networkId,
                dataPlanId: dataPlanId,
                phoneNumber: phoneNumber,
                amount: amount,
              ),
            },
            body: jsonEncode(<String, Object>{
              'network': int.tryParse(networkId) ?? 0,
              'data_type': dataType,
              'data_plan': dataPlanId,
              'phone_number': phoneNumber,
              'plant_amount': amount,
              'amount': amount,
              'validity': validity,
              'validaty': validity,
              'save_recipient': saveRecipient,
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return DataPurchaseApiResult.success(
          message:
              body['message']?.toString() ??
              'Your data purchase was completed successfully.',
          reference: body['reference']?.toString() ?? '',
          recentRecipients: _extractRecipients(body['recent_recipients']),
        );
      }

      if (response.statusCode == 401) {
        return DataPurchaseApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return DataPurchaseApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the data form and try again.',
        );
      }

      return DataPurchaseApiResult.failure(
        body['message']?.toString() ??
            'We could not complete this data purchase right now.',
        reference: body['reference']?.toString() ?? '',
        recentRecipients: _extractRecipients(body['recent_recipients']),
        fieldErrors: _extractFieldErrors(body['errors']),
      );
    } on TimeoutException {
      return const DataPurchaseApiResult.failure(
        'The data request is taking longer than expected. Please wait a moment and check your transaction history before trying again.',
      );
    } catch (_) {
      return const DataPurchaseApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<DataApiNetwork> _extractNetworks(Object? value) {
    if (value is! List) {
      return const <DataApiNetwork>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(DataApiNetwork.fromJson)
        .toList(growable: false);
  }

  List<DataSavedRecipient> _extractRecipients(Object? value) {
    if (value is! List) {
      return const <DataSavedRecipient>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(DataSavedRecipient.fromJson)
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
    required String networkId,
    required String dataPlanId,
    required String phoneNumber,
    required double amount,
  }) {
    final String normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D+'), '');
    final String normalizedAmount = amount.toStringAsFixed(2);
    return 'data-$networkId-$dataPlanId-$normalizedPhone-$normalizedAmount-${DateTime.now().microsecondsSinceEpoch}';
  }

  static void resetDebugHandlers() {
    debugCatalogHandler = null;
    debugRecipientsHandler = null;
    debugPurchaseHandler = null;
  }
}

class DataApiNetwork {
  const DataApiNetwork({
    required this.key,
    required this.networkId,
    required this.networkName,
    required this.purchaseNetworkId,
    required this.types,
  });

  factory DataApiNetwork.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTypes =
        json['types'] is List ? json['types'] as List<dynamic> : <dynamic>[];

    return DataApiNetwork(
      key: json['key']?.toString() ?? '',
      networkId: json['network_id']?.toString() ?? '',
      networkName: json['network_name']?.toString() ?? '',
      purchaseNetworkId:
          json['purchase_network_id']?.toString() ??
          json['network_id']?.toString() ??
          '',
      types: rawTypes
          .whereType<Map<String, dynamic>>()
          .map(DataApiType.fromJson)
          .toList(growable: false),
    );
  }

  final String key;
  final String networkId;
  final String networkName;
  final String purchaseNetworkId;
  final List<DataApiType> types;
}

class DataApiType {
  const DataApiType({
    required this.key,
    required this.label,
    required this.plans,
  });

  factory DataApiType.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPlans =
        json['plans'] is List ? json['plans'] as List<dynamic> : <dynamic>[];

    return DataApiType(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      plans: rawPlans
          .whereType<Map<String, dynamic>>()
          .map(DataApiPlan.fromJson)
          .toList(growable: false),
    );
  }

  final String key;
  final String label;
  final List<DataApiPlan> plans;
}

class DataApiPlan {
  const DataApiPlan({
    required this.id,
    required this.dataPlanId,
    required this.name,
    required this.validity,
    required this.amount,
    required this.networkId,
    required this.providerNetworkId,
  });

  factory DataApiPlan.fromJson(Map<String, dynamic> json) {
    return DataApiPlan(
      id: json['id']?.toString() ?? '',
      dataPlanId:
          json['data_plan_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      validity: json['validity']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      networkId: json['network_id']?.toString() ?? '',
      providerNetworkId: json['provider_network_id']?.toString() ?? '',
    );
  }

  final String id;
  final String dataPlanId;
  final String name;
  final String validity;
  final double amount;
  final String networkId;
  final String providerNetworkId;
}

class DataSavedRecipient {
  const DataSavedRecipient({
    required this.id,
    required this.phoneNumber,
    required this.networkId,
    required this.networkName,
    required this.usageCount,
    required this.lastUsedAt,
  });

  factory DataSavedRecipient.fromJson(Map<String, dynamic> json) {
    return DataSavedRecipient(
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

class DataCatalogApiResult {
  const DataCatalogApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.providerChannel = 'primary',
    this.networks = const <DataApiNetwork>[],
    this.recentRecipients = const <DataSavedRecipient>[],
    this.message,
  });

  const DataCatalogApiResult.success({
    required String providerChannel,
    required List<DataApiNetwork> networks,
    required List<DataSavedRecipient> recentRecipients,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         providerChannel: providerChannel,
         networks: networks,
         recentRecipients: recentRecipients,
       );

  const DataCatalogApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const DataCatalogApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final String providerChannel;
  final List<DataApiNetwork> networks;
  final List<DataSavedRecipient> recentRecipients;
  final String? message;
}

class DataRecipientsApiResult {
  const DataRecipientsApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.recipients = const <DataSavedRecipient>[],
    this.message,
  });

  const DataRecipientsApiResult.success({
    required List<DataSavedRecipient> recipients,
  }) : this._(isSuccess: true, isUnauthorized: false, recipients: recipients);

  const DataRecipientsApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const DataRecipientsApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<DataSavedRecipient> recipients;
  final String? message;
}

class DataPurchaseApiResult {
  const DataPurchaseApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.isValidationError,
    this.message,
    this.reference = '',
    this.recentRecipients = const <DataSavedRecipient>[],
    this.fieldErrors = const <String, String>{},
  });

  const DataPurchaseApiResult.success({
    required String message,
    required String reference,
    required List<DataSavedRecipient> recentRecipients,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         isValidationError: false,
         message: message,
         reference: reference,
         recentRecipients: recentRecipients,
       );

  const DataPurchaseApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        isValidationError: false,
        message: message,
      );

  const DataPurchaseApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const DataPurchaseApiResult.failure(
    String message, {
    String reference = '',
    List<DataSavedRecipient> recentRecipients = const <DataSavedRecipient>[],
    Map<String, String> fieldErrors = const <String, String>{},
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: false,
         message: message,
         reference: reference,
         recentRecipients: recentRecipients,
         fieldErrors: fieldErrors,
       );

  final bool isSuccess;
  final bool isUnauthorized;
  final bool isValidationError;
  final String? message;
  final String reference;
  final List<DataSavedRecipient> recentRecipients;
  final Map<String, String> fieldErrors;
}
