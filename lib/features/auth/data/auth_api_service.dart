import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef RegisterRequestHandler =
    Future<RegisterApiResult> Function({
      required String name,
      required String email,
      required String mobileNumber,
      required String username,
      required String password,
      required String passwordConfirmation,
      required String referralUsername,
    });

typedef LoginRequestHandler =
    Future<LoginApiResult> Function({
      required String login,
      required String password,
      required bool remember,
    });

typedef QuickUnlockRequestHandler =
    Future<QuickUnlockApiResult> Function({
      required String identifier,
      required String pin,
    });

typedef VerifyTransactionPinRequestHandler =
    Future<VerifyTransactionPinApiResult> Function({
      required String token,
      required String pin,
    });

typedef ForgotPasswordRequestHandler =
    Future<ForgotPasswordApiResult> Function({required String email});
typedef ResetPasswordRequestHandler =
    Future<ResetPasswordApiResult> Function({
      required String token,
      required String email,
      required String password,
      required String passwordConfirmation,
    });

class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();
  static RegisterRequestHandler? debugRegisterHandler;
  static LoginRequestHandler? debugLoginHandler;
  static QuickUnlockRequestHandler? debugQuickUnlockHandler;
  static VerifyTransactionPinRequestHandler? debugVerifyTransactionPinHandler;
  static ForgotPasswordRequestHandler? debugForgotPasswordHandler;
  static ResetPasswordRequestHandler? debugResetPasswordHandler;

  final http.Client _client = http.Client();

  Future<RegisterApiResult> register({
    required String name,
    required String email,
    required String mobileNumber,
    required String username,
    required String password,
    required String passwordConfirmation,
    required String referralUsername,
  }) async {
    final RegisterRequestHandler? handler = debugRegisterHandler;
    if (handler != null) {
      return handler(
        name: name,
        email: email,
        mobileNumber: mobileNumber,
        username: username,
        password: password,
        passwordConfirmation: passwordConfirmation,
        referralUsername: referralUsername,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/auth/register');

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'mobile_number': mobileNumber,
          'username': username,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'r_username': referralUsername,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 201) {
        return RegisterApiResult.success(
          session: _buildSession(body, fallbackIdentifier: email),
          message:
              body['message']?.toString() ?? 'Account created successfully.',
        );
      }

      if (response.statusCode == 422) {
        return RegisterApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message: body['message']?.toString() ?? 'Please correct the form.',
        );
      }

      return RegisterApiResult.failure(
        body['message']?.toString() ??
            'We could not create your account right now.',
      );
    } catch (_) {
      return const RegisterApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<LoginApiResult> login({
    required String login,
    required String password,
    required bool remember,
  }) async {
    final LoginRequestHandler? handler = debugLoginHandler;
    if (handler != null) {
      return handler(login: login, password: password, remember: remember);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/auth/login');

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, Object>{
          'login': login,
          'password': password,
          'remember': remember,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return LoginApiResult.success(
          session: _buildSession(body, fallbackIdentifier: login),
          message: body['message']?.toString() ?? 'Login successful.',
        );
      }

      if (response.statusCode == 422) {
        return LoginApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please check your login details and try again.',
        );
      }

      return LoginApiResult.failure(
        body['message']?.toString() ?? 'We could not sign you in right now.',
      );
    } catch (_) {
      return const LoginApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<ForgotPasswordApiResult> forgotPassword({
    required String email,
  }) async {
    final ForgotPasswordRequestHandler? handler = debugForgotPasswordHandler;
    if (handler != null) {
      return handler(email: email);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/auth/forgot-password',
    );

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, String>{'email': email}),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return ForgotPasswordApiResult.success(
          body['message']?.toString() ??
              'We have emailed your password reset link.',
        );
      }

      if (response.statusCode == 422) {
        return ForgotPasswordApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message: body['message']?.toString() ?? 'Please enter a valid email.',
        );
      }

      return ForgotPasswordApiResult.failure(
        body['message']?.toString() ??
            'We could not send the reset link right now.',
      );
    } catch (_) {
      return const ForgotPasswordApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<ResetPasswordApiResult> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final ResetPasswordRequestHandler? handler = debugResetPasswordHandler;
    if (handler != null) {
      return handler(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/auth/reset-password',
    );

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, String>{
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return ResetPasswordApiResult.success(
          body['message']?.toString() ?? 'Password reset successful.',
        );
      }

      if (response.statusCode == 422) {
        return ResetPasswordApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please correct the reset details and try again.',
        );
      }

      return ResetPasswordApiResult.failure(
        body['message']?.toString() ??
            'We could not reset your password right now.',
      );
    } catch (_) {
      return const ResetPasswordApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<VerifyTransactionPinApiResult> verifyTransactionPin({
    required String token,
    required String pin,
  }) async {
    final VerifyTransactionPinRequestHandler? handler =
        debugVerifyTransactionPinHandler;
    if (handler != null) {
      return handler(token: token, pin: pin);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/auth/verify-transaction-pin',
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
        body: jsonEncode(<String, String>{'pin': pin}),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return VerifyTransactionPinApiResult.success(
          body['message']?.toString() ??
              'Transaction PIN verified successfully.',
        );
      }

      if (response.statusCode == 401) {
        return VerifyTransactionPinApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return VerifyTransactionPinApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please confirm your transaction PIN and try again.',
        );
      }

      return VerifyTransactionPinApiResult.failure(
        body['message']?.toString() ??
            'We could not verify your transaction PIN right now.',
      );
    } catch (_) {
      return const VerifyTransactionPinApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<QuickUnlockApiResult> quickUnlock({
    required String identifier,
    required String pin,
  }) async {
    final QuickUnlockRequestHandler? handler = debugQuickUnlockHandler;
    if (handler != null) {
      return handler(identifier: identifier, pin: pin);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/auth/quick-unlock',
    );

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, String>{
          'identifier': identifier,
          'pin': pin,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return QuickUnlockApiResult.success(
          session: _buildSession(body, fallbackIdentifier: identifier),
          message: body['message']?.toString() ?? 'Quick login successful.',
        );
      }

      if (response.statusCode == 422) {
        return QuickUnlockApiResult.validation(
          fieldErrors: _extractFieldErrors(body['errors']),
          message:
              body['message']?.toString() ??
              'Please confirm your transaction PIN and try again.',
        );
      }

      return QuickUnlockApiResult.failure(
        body['message']?.toString() ??
            'We could not unlock your account right now.',
      );
    } catch (_) {
      return const QuickUnlockApiResult.failure(
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

  Map<String, String> _extractFieldErrors(Object? rawErrors) {
    if (rawErrors is! Map) {
      return <String, String>{};
    }

    final Map<String, String> result = <String, String>{};
    rawErrors.forEach((Object? key, Object? value) {
      final String field = key?.toString() ?? '';
      if (field.isEmpty) {
        return;
      }

      if (value is List && value.isNotEmpty) {
        result[field] = value.first.toString();
        return;
      }

      if (value != null) {
        result[field] = value.toString();
      }
    });

    return result;
  }

  MobileAuthSession _buildSession(
    Map<String, dynamic> body, {
    required String fallbackIdentifier,
  }) {
    final Map<String, dynamic> user =
        body['user'] is Map<String, dynamic>
            ? body['user'] as Map<String, dynamic>
            : <String, dynamic>{};

    final String username = user['username']?.toString() ?? '';
    final String name = user['name']?.toString() ?? '';

    return MobileAuthSession(
      token: body['token']?.toString() ?? '',
      displayName: username.isNotEmpty ? username.toUpperCase() : name,
      identifier: user['email']?.toString() ?? fallbackIdentifier,
      hasTransactionPin: user['has_transaction_pin'] == true,
    );
  }

  static void resetDebugHandlers() {
    debugRegisterHandler = null;
    debugLoginHandler = null;
    debugQuickUnlockHandler = null;
    debugVerifyTransactionPinHandler = null;
    debugForgotPasswordHandler = null;
    debugResetPasswordHandler = null;
  }
}

class MobileAuthSession {
  const MobileAuthSession({
    required this.token,
    required this.displayName,
    required this.identifier,
    required this.hasTransactionPin,
  });

  final String token;
  final String displayName;
  final String identifier;
  final bool hasTransactionPin;
}

class RegisterApiResult {
  const RegisterApiResult._({
    required this.isSuccess,
    required this.isValidationError,
    this.session,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const RegisterApiResult.success({
    required MobileAuthSession session,
    String? message,
  }) : this._(
         isSuccess: true,
         isValidationError: false,
         session: session,
         message: message,
       );

  const RegisterApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const RegisterApiResult.failure(String message)
    : this._(isSuccess: false, isValidationError: false, message: message);

  final bool isSuccess;
  final bool isValidationError;
  final MobileAuthSession? session;
  final String? message;
  final Map<String, String> fieldErrors;
}

class LoginApiResult {
  const LoginApiResult._({
    required this.isSuccess,
    required this.isValidationError,
    this.session,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const LoginApiResult.success({
    required MobileAuthSession session,
    String? message,
  }) : this._(
         isSuccess: true,
         isValidationError: false,
         session: session,
         message: message,
       );

  const LoginApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const LoginApiResult.failure(String message)
    : this._(isSuccess: false, isValidationError: false, message: message);

  final bool isSuccess;
  final bool isValidationError;
  final MobileAuthSession? session;
  final String? message;
  final Map<String, String> fieldErrors;
}

class ForgotPasswordApiResult {
  const ForgotPasswordApiResult._({
    required this.isSuccess,
    required this.isValidationError,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const ForgotPasswordApiResult.success(String message)
    : this._(isSuccess: true, isValidationError: false, message: message);

  const ForgotPasswordApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const ForgotPasswordApiResult.failure(String message)
    : this._(isSuccess: false, isValidationError: false, message: message);

  final bool isSuccess;
  final bool isValidationError;
  final String? message;
  final Map<String, String> fieldErrors;
}

class ResetPasswordApiResult {
  const ResetPasswordApiResult._({
    required this.isSuccess,
    required this.isValidationError,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const ResetPasswordApiResult.success(String message)
    : this._(isSuccess: true, isValidationError: false, message: message);

  const ResetPasswordApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isValidationError: true,
         message: message,
         fieldErrors: fieldErrors,
       );

  const ResetPasswordApiResult.failure(String message)
    : this._(isSuccess: false, isValidationError: false, message: message);

  final bool isSuccess;
  final bool isValidationError;
  final String? message;
  final Map<String, String> fieldErrors;
}

class QuickUnlockApiResult {
  const QuickUnlockApiResult._({
    required this.isSuccess,
    required this.isValidationError,
    this.session,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const QuickUnlockApiResult.success({
    required MobileAuthSession session,
    String? message,
  }) : this._(
         isSuccess: true,
         isValidationError: false,
         session: session,
         message: message,
       );

  const QuickUnlockApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isValidationError: true,
         fieldErrors: fieldErrors,
         message: message,
       );

  const QuickUnlockApiResult.failure(String message)
    : this._(isSuccess: false, isValidationError: false, message: message);

  final bool isSuccess;
  final bool isValidationError;
  final MobileAuthSession? session;
  final String? message;
  final Map<String, String> fieldErrors;
}

class VerifyTransactionPinApiResult {
  const VerifyTransactionPinApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.isValidationError,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  const VerifyTransactionPinApiResult.success(String message)
    : this._(
        isSuccess: true,
        isUnauthorized: false,
        isValidationError: false,
        message: message,
      );

  const VerifyTransactionPinApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        isValidationError: false,
        message: message,
      );

  const VerifyTransactionPinApiResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         isValidationError: true,
         message: message,
         fieldErrors: fieldErrors,
       );

  const VerifyTransactionPinApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        isValidationError: false,
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final bool isValidationError;
  final String? message;
  final Map<String, String> fieldErrors;
}
