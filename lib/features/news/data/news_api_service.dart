import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef NewsFetchHandler =
    Future<NewsApiResult> Function({required String token, required int limit});

class NewsApiService {
  NewsApiService._();

  static final NewsApiService instance = NewsApiService._();
  static NewsFetchHandler? debugFetchHandler;

  final http.Client _client = http.Client();

  Future<NewsApiResult> fetchNews({
    required String token,
    int limit = 20,
  }) async {
    final NewsFetchHandler? handler = debugFetchHandler;
    if (handler != null) {
      return handler(token: token, limit: limit);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/news',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});

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
        final List<NewsItem> items =
            data['items'] is List
                ? (data['items'] as List<dynamic>)
                    .whereType<Map<String, dynamic>>()
                    .map(NewsItem.fromJson)
                    .toList(growable: false)
                : const <NewsItem>[];

        return NewsApiResult.success(
          items: items,
          message: body['message']?.toString() ?? 'News loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return NewsApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return NewsApiResult.failure(
        body['message']?.toString() ??
            'We could not load your news updates right now.',
      );
    } catch (_) {
      return const NewsApiResult.failure(
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

class NewsItem {
  const NewsItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.createdLabel,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      createdLabel: json['created_label']?.toString() ?? '',
    );
  }

  final int id;
  final String message;
  final DateTime createdAt;
  final String createdLabel;
}

class NewsApiResult {
  const NewsApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.items = const <NewsItem>[],
    this.message,
  });

  const NewsApiResult.success({required List<NewsItem> items, String? message})
    : this._(
        isSuccess: true,
        isUnauthorized: false,
        items: items,
        message: message,
      );

  const NewsApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const NewsApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<NewsItem> items;
  final String? message;
}
