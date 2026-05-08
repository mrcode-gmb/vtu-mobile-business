import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef ProfileRequestHandler =
    Future<ProfileApiResult> Function({required String token});
typedef ProfileUpdateRequestHandler =
    Future<ProfileApiResult> Function({
      required String token,
      required String name,
      required String email,
      required String mobileNumber,
    });

class ProfileApiService {
  ProfileApiService._();

  static final ProfileApiService instance = ProfileApiService._();
  static ProfileRequestHandler? debugProfileHandler;
  static ProfileUpdateRequestHandler? debugProfileUpdateHandler;

  final http.Client _client = http.Client();

  Future<ProfileApiResult> fetchProfile({required String token}) async {
    final ProfileRequestHandler? handler = debugProfileHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/profile');

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
        return ProfileApiResult.success(
          profile: ProfileDetails.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ?? 'Profile loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return ProfileApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return ProfileApiResult.failure(
        body['message']?.toString() ??
            'We could not load your profile right now.',
      );
    } catch (_) {
      return const ProfileApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<ProfileApiResult> updateProfile({
    required String token,
    required String name,
    required String email,
    required String mobileNumber,
  }) async {
    final ProfileUpdateRequestHandler? handler = debugProfileUpdateHandler;
    if (handler != null) {
      return handler(
        token: token,
        name: name,
        email: email,
        mobileNumber: mobileNumber,
      );
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/profile');

    try {
      final http.Response response = await _client.patch(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Airplug-App': '1',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'mobile_number': mobileNumber,
        }),
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return ProfileApiResult.success(
          profile: ProfileDetails.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ?? 'Profile updated successfully.',
        );
      }

      if (response.statusCode == 401) {
        return ProfileApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422) {
        return ProfileApiResult.validation(
          message:
              body['message']?.toString() ??
              'Please correct the profile details and try again.',
          fieldErrors: _extractFieldErrors(body['errors']),
        );
      }

      return ProfileApiResult.failure(
        body['message']?.toString() ??
            'We could not update your profile right now.',
      );
    } catch (_) {
      return const ProfileApiResult.failure(
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

  static void resetDebugHandlers() {
    debugProfileHandler = null;
    debugProfileUpdateHandler = null;
  }
}

class ProfileDetails {
  const ProfileDetails({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.username,
    required this.referralCode,
    required this.referralUsername,
    required this.role,
    required this.roleLabel,
    required this.accountType,
    required this.tierLabel,
    required this.status,
    required this.statusLabel,
    required this.verificationLabel,
    required this.pinStatusLabel,
    required this.profileCompleted,
    required this.isEmailVerified,
    required this.hasTransactionPin,
    required this.walletBalance,
    required this.cashbackBalance,
    required this.joinedAt,
    required this.joinedLabel,
  });

  const ProfileDetails.empty()
    : name = 'PTS DATA User',
      email = '',
      mobileNumber = '',
      username = '',
      referralCode = '',
      referralUsername = '',
      role = 'user',
      roleLabel = 'Standard',
      accountType = '',
      tierLabel = 'Tier 1',
      status = '',
      statusLabel = 'Active',
      verificationLabel = 'Pending',
      pinStatusLabel = 'Not Set',
      profileCompleted = false,
      isEmailVerified = false,
      hasTransactionPin = false,
      walletBalance = 0,
      cashbackBalance = 0,
      joinedAt = null,
      joinedLabel = 'Member';

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    return ProfileDetails(
      name: json['name']?.toString() ?? 'PTS DATA User',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      referralCode: json['referral_code']?.toString() ?? '',
      referralUsername: json['referral_username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      roleLabel: json['role_label']?.toString() ?? 'Standard',
      accountType: json['account_type']?.toString() ?? '',
      tierLabel: json['tier_label']?.toString() ?? 'Tier 1',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? 'Active',
      verificationLabel: json['verification_label']?.toString() ?? 'Pending',
      pinStatusLabel: json['pin_status_label']?.toString() ?? 'Not Set',
      profileCompleted: json['profile_completed'] == true,
      isEmailVerified: json['is_email_verified'] == true,
      hasTransactionPin: json['has_transaction_pin'] == true,
      walletBalance: _toDouble(json['wallet_balance']),
      cashbackBalance: _toDouble(json['cashback_balance']),
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
      joinedLabel: json['joined_label']?.toString() ?? 'Member',
    );
  }

  final String name;
  final String email;
  final String mobileNumber;
  final String username;
  final String referralCode;
  final String referralUsername;
  final String role;
  final String roleLabel;
  final String accountType;
  final String tierLabel;
  final String status;
  final String statusLabel;
  final String verificationLabel;
  final String pinStatusLabel;
  final bool profileCompleted;
  final bool isEmailVerified;
  final bool hasTransactionPin;
  final double walletBalance;
  final double cashbackBalance;
  final DateTime? joinedAt;
  final String joinedLabel;

  bool get hasReferralCode => referralCode.trim().isNotEmpty;
}

class ProfileApiResult {
  const ProfileApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.fieldErrors,
    this.profile,
    this.message,
  });

  const ProfileApiResult.success({
    required ProfileDetails profile,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         fieldErrors: const <String, String>{},
         profile: profile,
         message: message,
       );

  const ProfileApiResult.validation({
    required String message,
    required Map<String, String> fieldErrors,
  }) : this._(
         isSuccess: false,
         isUnauthorized: false,
         fieldErrors: fieldErrors,
         message: message,
       );

  const ProfileApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        fieldErrors: const <String, String>{},
        message: message,
      );

  const ProfileApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        fieldErrors: const <String, String>{},
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final Map<String, String> fieldErrors;
  final ProfileDetails? profile;
  final String? message;
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
