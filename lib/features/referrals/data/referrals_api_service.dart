import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

typedef ReferralsOverviewHandler =
    Future<ReferralsOverviewApiResult> Function({required String token});
typedef ReferralsClaimHandler =
    Future<ReferralsClaimApiResult> Function({
      required String token,
      required String referralId,
    });

class ReferralsApiService {
  ReferralsApiService._();

  static final ReferralsApiService instance = ReferralsApiService._();
  static ReferralsOverviewHandler? debugOverviewHandler;
  static ReferralsClaimHandler? debugClaimHandler;

  final http.Client _client = http.Client();

  Future<ReferralsOverviewApiResult> fetchOverview({
    required String token,
  }) async {
    final ReferralsOverviewHandler? handler = debugOverviewHandler;
    if (handler != null) {
      return handler(token: token);
    }

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/mobile/referrals');

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
        return ReferralsOverviewApiResult.success(
          overview: ReferralsOverview.fromJson(
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{},
          ),
          message:
              body['message']?.toString() ?? 'Referrals loaded successfully.',
        );
      }

      if (response.statusCode == 401) {
        return ReferralsOverviewApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      return ReferralsOverviewApiResult.failure(
        body['message']?.toString() ?? 'We could not load referrals right now.',
      );
    } catch (_) {
      return const ReferralsOverviewApiResult.failure(
        'We could not reach the PTS DATA server. Check the API URL and try again.',
      );
    }
  }

  Future<ReferralsClaimApiResult> claimReward({
    required String token,
    required String referralId,
  }) async {
    final ReferralsClaimHandler? handler = debugClaimHandler;
    if (handler != null) {
      return handler(token: token, referralId: referralId);
    }

    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/referrals/${Uri.encodeComponent(referralId)}/claim',
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
      );

      final Map<String, dynamic> body = _decodeObject(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
        return ReferralsClaimApiResult.success(
          claimedAmount: _toDouble(data['claimed_amount']),
          walletBalance: _toDouble(data['wallet_balance']),
          overview:
              data['overview'] is Map<String, dynamic>
                  ? ReferralsOverview.fromJson(
                    data['overview'] as Map<String, dynamic>,
                  )
                  : null,
          message:
              body['message']?.toString() ??
              'Referral reward claimed successfully.',
        );
      }

      if (response.statusCode == 401) {
        return ReferralsClaimApiResult.unauthorized(
          body['message']?.toString() ?? 'Your session has expired.',
        );
      }

      if (response.statusCode == 422 || response.statusCode == 400) {
        return ReferralsClaimApiResult.failure(
          body['message']?.toString() ??
              _firstValidationMessage(body['errors']) ??
              'We could not claim this referral reward right now.',
        );
      }

      return ReferralsClaimApiResult.failure(
        body['message']?.toString() ??
            'We could not claim this referral reward right now.',
      );
    } catch (_) {
      return const ReferralsClaimApiResult.failure(
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
    debugOverviewHandler = null;
    debugClaimHandler = null;
  }
}

class ReferralsOverview {
  const ReferralsOverview({
    required this.referralCode,
    required this.inviteLink,
    required this.rewardPerReferral,
    required this.totalReferrals,
    required this.claimableCount,
    required this.claimedCount,
    required this.totalEarned,
    required this.claimableAmount,
    required this.walletBalance,
    required this.items,
  });

  factory ReferralsOverview.fromJson(Map<String, dynamic> json) {
    return ReferralsOverview(
      referralCode: json['referral_code']?.toString() ?? '',
      inviteLink: json['invite_link']?.toString() ?? '',
      rewardPerReferral: _toDouble(json['reward_per_referral']),
      totalReferrals:
          int.tryParse(json['total_referrals']?.toString() ?? '') ?? 0,
      claimableCount:
          int.tryParse(json['claimable_count']?.toString() ?? '') ?? 0,
      claimedCount: int.tryParse(json['claimed_count']?.toString() ?? '') ?? 0,
      totalEarned: _toDouble(json['total_earned']),
      claimableAmount: _toDouble(json['claimable_amount']),
      walletBalance: _toDouble(json['wallet_balance']),
      items:
          json['items'] is List
              ? (json['items'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(ReferralApiItem.fromJson)
                  .toList(growable: false)
              : const <ReferralApiItem>[],
    );
  }

  final String referralCode;
  final String inviteLink;
  final double rewardPerReferral;
  final int totalReferrals;
  final int claimableCount;
  final int claimedCount;
  final double totalEarned;
  final double claimableAmount;
  final double walletBalance;
  final List<ReferralApiItem> items;
}

class ReferralApiItem {
  const ReferralApiItem({
    required this.id,
    required this.index,
    required this.referralType,
    required this.name,
    required this.reward,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.createdLabel,
  });

  factory ReferralApiItem.fromJson(Map<String, dynamic> json) {
    return ReferralApiItem(
      id: json['id']?.toString() ?? '',
      index: int.tryParse(json['index']?.toString() ?? '') ?? 0,
      referralType: json['referral_type']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Referral User',
      reward: _toDouble(json['reward']),
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
      statusLabel: json['status_label']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      createdLabel: json['created_label']?.toString() ?? '',
    );
  }

  final String id;
  final int index;
  final String referralType;
  final String name;
  final double reward;
  final int status;
  final String statusLabel;
  final DateTime? createdAt;
  final String createdLabel;
}

class ReferralsOverviewApiResult {
  const ReferralsOverviewApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    this.overview,
    this.message,
  });

  const ReferralsOverviewApiResult.success({
    required ReferralsOverview overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         overview: overview,
         message: message,
       );

  const ReferralsOverviewApiResult.failure(String message)
    : this._(isSuccess: false, isUnauthorized: false, message: message);

  const ReferralsOverviewApiResult.unauthorized(String message)
    : this._(isSuccess: false, isUnauthorized: true, message: message);

  final bool isSuccess;
  final bool isUnauthorized;
  final ReferralsOverview? overview;
  final String? message;
}

class ReferralsClaimApiResult {
  const ReferralsClaimApiResult._({
    required this.isSuccess,
    required this.isUnauthorized,
    required this.claimedAmount,
    required this.walletBalance,
    this.overview,
    this.message,
  });

  const ReferralsClaimApiResult.success({
    required double claimedAmount,
    required double walletBalance,
    ReferralsOverview? overview,
    String? message,
  }) : this._(
         isSuccess: true,
         isUnauthorized: false,
         claimedAmount: claimedAmount,
         walletBalance: walletBalance,
         overview: overview,
         message: message,
       );

  const ReferralsClaimApiResult.failure(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: false,
        claimedAmount: 0,
        walletBalance: 0,
        message: message,
      );

  const ReferralsClaimApiResult.unauthorized(String message)
    : this._(
        isSuccess: false,
        isUnauthorized: true,
        claimedAmount: 0,
        walletBalance: 0,
        message: message,
      );

  final bool isSuccess;
  final bool isUnauthorized;
  final double claimedAmount;
  final double walletBalance;
  final ReferralsOverview? overview;
  final String? message;
}

double _toDouble(Object? value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

String? _firstValidationMessage(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  for (final dynamic current in value.values) {
    if (current is List && current.isNotEmpty) {
      return current.first.toString();
    }
    if (current != null) {
      return current.toString();
    }
  }

  return null;
}
