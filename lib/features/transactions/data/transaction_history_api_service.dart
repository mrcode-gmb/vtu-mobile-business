import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef TransactionHistoryFetchHandler =
    Future<TransactionHistoryApiResult> Function({
      required String token,
      required int page,
      required String type,
      required String status,
      required String dateRange,
      required String search,
    });

typedef TransactionHistoryExportHandler =
    Future<TransactionHistoryExportApiResult> Function({
      required String token,
      required String format,
      required String type,
      required String status,
      required String dateRange,
      required String search,
    });

class TransactionHistoryApiService {
  TransactionHistoryApiService._();

  static final TransactionHistoryApiService instance =
      TransactionHistoryApiService._();
  static TransactionHistoryFetchHandler? debugFetchHandler;
  static TransactionHistoryExportHandler? debugExportHandler;

  final http.Client _client = http.Client();

  Future<TransactionHistoryApiResult> fetchTransactions({
    required String token,
    required int page,
    required String type,
    required String status,
    required String dateRange,
    required String search,
  }) async {
    final TransactionHistoryFetchHandler? handler = debugFetchHandler;
    if (handler != null) {
      return handler(
        token: token,
        page: page,
        type: type,
        status: status,
        dateRange: dateRange,
        search: search,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/transaction-history',
    ).replace(
      queryParameters: <String, String>{
        'page': '$page',
        'type': type,
        'status': status,
        'date_range': dateRange,
        'search': search,
      },
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
        return TransactionHistoryApiResult.success(
          page: TransactionHistoryPagePayload.fromJson(
            body['transactions'] is Map<String, dynamic>
                ? body['transactions'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ??
              'Transactions loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return TransactionHistoryApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return TransactionHistoryApiResult.failure(
        body['message']?.toString() ??
            'We could not load your transactions right now.',
      );
    } catch (_) {
      return const TransactionHistoryApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<TransactionHistoryExportApiResult> exportTransactions({
    required String token,
    required String format,
    required String type,
    required String status,
    required String dateRange,
    required String search,
  }) async {
    final TransactionHistoryExportHandler? handler = debugExportHandler;
    if (handler != null) {
      return handler(
        token: token,
        format: format,
        type: type,
        status: status,
        dateRange: dateRange,
        search: search,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/transaction-history/export',
    ).replace(
      queryParameters: <String, String>{
        'format': format,
        'type': type,
        'status': status,
        'date_range': dateRange,
        'search': search,
      },
    );

    try {
      final http.Response response = await _client.get(
        uri,
        headers: <String, String>{
          'Accept': 'text/csv,application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
        },
      );

      if (response.statusCode == 200) {
        return TransactionHistoryExportApiResult.success(
          bytes: response.bodyBytes,
          fileName: _extractFileName(response) ?? 'transactions_export.csv',
          mimeType: response.headers['content-type'] ?? 'text/csv',
          message: 'Transactions exported successfully.',
        );
      }

      if (response.statusCode == 401) {
        final Map<String, dynamic> body = _decodeObject(response.body);
        return TransactionHistoryExportApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      final Map<String, dynamic> body = _decodeObject(response.body);
      return TransactionHistoryExportApiResult.failure(
        body['message']?.toString() ??
            'We could not export transactions right now.',
      );
    } catch (_) {
      return const TransactionHistoryExportApiResult.failure(
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

  String? _extractFileName(http.Response response) {
    final String? disposition = response.headers['content-disposition'];
    if (disposition == null || disposition.isEmpty) {
      return null;
    }

    final RegExpMatch? match = RegExp(
      r'filename="?([^"]+)"?',
    ).firstMatch(disposition);
    return match?.group(1);
  }

  static void resetDebugHandlers() {
    debugFetchHandler = null;
    debugExportHandler = null;
  }
}

class TransactionHistoryPagePayload {
  const TransactionHistoryPagePayload({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory TransactionHistoryPagePayload.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryPagePayload(
      data:
          json['data'] is List
              ? (json['data'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(TransactionHistoryApiItem.fromJson)
                  .toList(growable: false)
              : const <TransactionHistoryApiItem>[],
      currentPage: int.tryParse(json['current_page']?.toString() ?? '') ?? 1,
      perPage: int.tryParse(json['per_page']?.toString() ?? '') ?? 20,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      lastPage: int.tryParse(json['last_page']?.toString() ?? '') ?? 1,
    );
  }

  final List<TransactionHistoryApiItem> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
}

class TransactionHistoryApiItem {
  const TransactionHistoryApiItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    required this.date,
    required this.description,
    this.recipient,
    this.reference,
    this.network,
    this.plan,
    this.quantity,
  });

  factory TransactionHistoryApiItem.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryApiItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'funding',
      amount: _toDouble(json['amount']),
      status: json['status']?.toString() ?? 'failed',
      direction: json['direction']?.toString() ?? 'outgoing',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      description: json['description']?.toString() ?? 'Transaction',
      recipient: json['recipient']?.toString(),
      reference: json['reference']?.toString(),
      network: json['network']?.toString(),
      plan: json['plan']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? ''),
    );
  }

  final String id;
  final String type;
  final double amount;
  final String status;
  final String direction;
  final DateTime date;
  final String description;
  final String? recipient;
  final String? reference;
  final String? network;
  final String? plan;
  final int? quantity;
}

class TransactionHistoryApiResult {
  const TransactionHistoryApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.page,
    this.message,
  });

  const TransactionHistoryApiResult.success({
    required TransactionHistoryPagePayload page,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         page: page,
         message: message,
       );

  const TransactionHistoryApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const TransactionHistoryApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final TransactionHistoryPagePayload? page;
  final String? message;
}

class TransactionHistoryExportApiResult {
  const TransactionHistoryExportApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.bytes,
    this.fileName,
    this.mimeType,
    this.message,
  });

  const TransactionHistoryExportApiResult.success({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         bytes: bytes,
         fileName: fileName,
         mimeType: mimeType,
         message: message,
       );

  const TransactionHistoryExportApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const TransactionHistoryExportApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<int>? bytes;
  final String? fileName;
  final String? mimeType;
  final String? message;
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
