import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../me/data/profile_api_service.dart';

typedef ChangePasswordRequestHandler =
    Future<AccountSecurityResult> Function({
      required String token,
      required String currentPassword,
      required String password,
      required String passwordConfirmation,
    });

typedef CreateTransactionPinRequestHandler =
    Future<AccountSecurityResult> Function({
      required String token,
      required String newPin,
      required String confirmPin,
    });

typedef ChangeTransactionPinRequestHandler =
    Future<AccountSecurityResult> Function({
      required String token,
      required String oldPin,
      required String newPin,
      required String confirmPin,
    });

typedef ResetTransactionPinRequestHandler =
    Future<AccountSecurityResult> Function({
      required String token,
      required String password,
      required String newPin,
      required String confirmPin,
    });

class AccountSecurityApiService {
  AccountSecurityApiService._();

  static final AccountSecurityApiService instance =
      AccountSecurityApiService._();
  static ChangePasswordRequestHandler? debugChangePasswordHandler;
  static CreateTransactionPinRequestHandler? debugCreateTransactionPinHandler;
  static ChangeTransactionPinRequestHandler? debugChangeTransactionPinHandler;
  static ResetTransactionPinRequestHandler? debugResetTransactionPinHandler;

  final http.Client _client = http.Client();

  static void resetDebugHandlers() {
    debugChangePasswordHandler = null;
    debugCreateTransactionPinHandler = null;
    debugChangeTransactionPinHandler = null;
    debugResetTransactionPinHandler = null;
  }

  Future<AccountSecurityResult> changePassword({
    required String token,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final ChangePasswordRequestHandler? handler = debugChangePasswordHandler;
    if (handler != null) {
      return handler(
        token: token,
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    }

    return _submit(
      token: token,
      method: 'PUT',
      path: '/mobile/security/password',
      payload: <String, String>{
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<AccountSecurityResult> createTransactionPin({
    required String token,
    required String newPin,
    required String confirmPin,
  }) async {
    final CreateTransactionPinRequestHandler? handler =
        debugCreateTransactionPinHandler;
    if (handler != null) {
      return handler(token: token, newPin: newPin, confirmPin: confirmPin);
    }

    return _submit(
      token: token,
      method: 'POST',
      path: '/mobile/security/transaction-pin',
      payload: <String, String>{'new_pin': newPin, 'confirm_pin': confirmPin},
    );
  }

  Future<AccountSecurityResult> changeTransactionPin({
    required String token,
    required String oldPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final ChangeTransactionPinRequestHandler? handler =
        debugChangeTransactionPinHandler;
    if (handler != null) {
      return handler(
        token: token,
        oldPin: oldPin,
        newPin: newPin,
        confirmPin: confirmPin,
      );
    }

    return _submit(
      token: token,
      method: 'PUT',
      path: '/mobile/security/transaction-pin',
      payload: <String, String>{
        'old_pin': oldPin,
        'new_pin': newPin,
        'confirm_pin': confirmPin,
      },
    );
  }

  Future<AccountSecurityResult> resetTransactionPin({
    required String token,
    required String password,
    required String newPin,
    required String confirmPin,
  }) async {
    final ResetTransactionPinRequestHandler? handler =
        debugResetTransactionPinHandler;
    if (handler != null) {
      return handler(
        token: token,
        password: password,
        newPin: newPin,
        confirmPin: confirmPin,
      );
    }

    return _submit(
      token: token,
      method: 'POST',
      path: '/mobile/security/transaction-pin/reset',
      payload: <String, String>{
        'your_password': password,
        'new_pin': newPin,
        'confirm_pin': confirmPin,
      },
    );
  }

  Future<AccountSecurityResult> _submit({
    required String token,
    required String method,
    required String path,
    required Map<String, String> payload,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    try {
      late http.Response response;
      final Map<String, String> headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Airplug-App': '1',
      };

      switch (method) {
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          );
          break;
        case 'POST':
        default:
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          );
      }

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return AccountSecurityResult.success(
          message: body['message']?.toString() ?? 'Security settings updated.',
          profile:
              body['profile'] is Map<String, dynamic>
                  ? ProfileDetails.fromJson(
                    body['profile'] as Map<String, dynamic>,
                  )
                  : null,
        );
      }

      if (response.statusCode == 401) {
        return AccountSecurityResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return AccountSecurityResult.validation(
          message:
              body['message']?.toString() ??
              'Please correct the form and try again.',
          fieldErrors: _extractFieldErrors(body['errors']),
        );
      }

      return AccountSecurityResult.failure(
        body['message']?.toString() ??
            'We could not complete this security action right now.',
      );
    } catch (_) {
      return const AccountSecurityResult.failure(
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
}

class AccountSecurityResult {
  const AccountSecurityResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.fieldErrors,
    this.message,
    this.profile,
  });

  const AccountSecurityResult.success({
    required String message,
    ProfileDetails? profile,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         fieldErrors: const <String, String>{},
         message: message,
         profile: profile,
       );

  const AccountSecurityResult.validation({
    required String message,
    required Map<String, String> fieldErrors,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         fieldErrors: fieldErrors,
         message: message,
       );

  const AccountSecurityResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        fieldErrors: const <String, String>{},
        message: message,
      );

  const AccountSecurityResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final Map<String, String> fieldErrors;
  final String? message;
  final ProfileDetails? profile;
}
