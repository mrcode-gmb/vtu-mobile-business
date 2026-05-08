import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef NotificationsFetchHandler =
    Future<NotificationsApiResult> Function({required String token});

typedef NotificationMarkReadHandler =
    Future<NotificationMutationApiResult> Function({
      required String token,
      required String notificationId,
    });

typedef NotificationsMarkAllReadHandler =
    Future<NotificationMutationApiResult> Function({required String token});

class NotificationApiService {
  NotificationApiService._();

  static final NotificationApiService instance = NotificationApiService._();
  static NotificationsFetchHandler? debugFetchHandler;
  static NotificationMarkReadHandler? debugMarkReadHandler;
  static NotificationsMarkAllReadHandler? debugMarkAllReadHandler;

  final http.Client _client = http.Client();

  Future<NotificationsApiResult> fetchNotifications({
    required String token,
  }) async {
    final NotificationsFetchHandler? handler = debugFetchHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/notifications');

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
        return NotificationsApiResult.success(
          notifications: _buildNotifications(body),
          unreadCount: _readUnreadCount(body),
          message:
              body['message']?.toString() ??
              'Notifications loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return NotificationsApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return NotificationsApiResult.failure(
        body['message']?.toString() ??
            'We could not load your notifications right now.',
      );
    } catch (_) {
      return const NotificationsApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<NotificationMutationApiResult> markAsRead({
    required String token,
    required String notificationId,
  }) async {
    final NotificationMarkReadHandler? handler = debugMarkReadHandler;
    if (handler != null) {
      return handler(token: token, notificationId: notificationId);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/notifications/$notificationId/read',
    );

    return _postMutation(uri: uri, token: token);
  }

  Future<NotificationMutationApiResult> markAllAsRead({
    required String token,
  }) async {
    final NotificationsMarkAllReadHandler? handler = debugMarkAllReadHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/notifications/read-all',
    );

    return _postMutation(uri: uri, token: token);
  }

  Future<NotificationMutationApiResult> _postMutation({
    required Uri uri,
    required String token,
  }) async {
    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
        },
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return NotificationMutationApiResult.success(
          unreadCount: _readUnreadCount(body),
          message:
              body['message']?.toString() ??
              'Notification updated successfully.',
        );
      }

      if (response.statusCode == 401) {
        return NotificationMutationApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return NotificationMutationApiResult.failure(
        body['message']?.toString() ??
            'We could not update your notifications right now.',
      );
    } catch (_) {
      return const NotificationMutationApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  List<NotificationApiItem> _buildNotifications(Map<String, dynamic> body) {
    final Map<String, dynamic> data =
        body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : <String, dynamic>{};
    final Object? notifications = data['notifications'];
    if (notifications is! List) {
      return const <NotificationApiItem>[];
    }

    return notifications
        .whereType<Map<String, dynamic>>()
        .map(NotificationApiItem.fromJson)
        .toList(growable: false);
  }

  int _readUnreadCount(Map<String, dynamic> body) {
    final Map<String, dynamic> data =
        body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : <String, dynamic>{};
    final Object? unreadCount = data['unread_count'];
    if (unreadCount is num) {
      return unreadCount.toInt();
    }

    return int.tryParse(unreadCount?.toString() ?? '') ?? 0;
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
    debugMarkReadHandler = null;
    debugMarkAllReadHandler = null;
  }
}

class NotificationApiItem {
  const NotificationApiItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationApiItem.fromJson(Map<String, dynamic> json) {
    return NotificationApiItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? 'You have a new notification.',
      category: json['category']?.toString() ?? 'info',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }

  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime createdAt;
  final bool isRead;
}

class NotificationsApiResult {
  const NotificationsApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.notifications = const <NotificationApiItem>[],
    this.unreadCount = 0,
    this.message,
  });

  const NotificationsApiResult.success({
    required List<NotificationApiItem> notifications,
    required int unreadCount,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         notifications: notifications,
         unreadCount: unreadCount,
         message: message,
       );

  const NotificationsApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const NotificationsApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final List<NotificationApiItem> notifications;
  final int unreadCount;
  final String? message;
}

class NotificationMutationApiResult {
  const NotificationMutationApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.unreadCount = 0,
    this.message,
  });

  const NotificationMutationApiResult.success({
    required int unreadCount,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         unreadCount: unreadCount,
         message: message,
       );

  const NotificationMutationApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  const NotificationMutationApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final int unreadCount;
  final String? message;
}
